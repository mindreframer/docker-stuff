package main

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"github.com/georgebashi/docker-simpleregistry/storage"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"net/http"
	"path/filepath"
	"strings"
)

func PingHandler(w http.ResponseWriter, r *http.Request) {
	sendResponse(w, nil, 200, nil, false)
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	sendResponse(w, "docker-simpleregistry server", 200, nil, false)
}

type Context struct {
	storage *storage.Storage
}

func (ctx *Context) GetImageLayerHandler(w http.ResponseWriter, r *http.Request) {
	imageId := mux.Vars(r)["imageId"]
	imageReader, err := ctx.storage.StreamRead(storage.ImageLayerPath(imageId))
	if err != nil {
		sendResponse(w, "image not found", 404, nil, false)
		return
	}
	defer imageReader.Close()

	io.Copy(w, imageReader)
}

func (ctx *Context) PutImageLayerHandler(w http.ResponseWriter, r *http.Request) {
	imageId := mux.Vars(r)["imageId"]
	jsonData, err := ctx.storage.GetContent(storage.ImageJsonPath(imageId))
	if err != nil {
		sendResponse(w, "Image's JSON not found", 404, nil, false)
		return
	}

	checksum, err := ctx.storage.GetContent(storage.ImageChecksumPath(imageId))
	if err != nil {
		sendResponse(w, "Image's checksum not found", 404, nil, false)
		return
	}

	layerPath := storage.ImageLayerPath(imageId)
	markPath := storage.ImageMarkPath(imageId)

	if layerExists, err := ctx.storage.Exists(layerPath); layerExists == true && err == nil {
		if markExists, err := ctx.storage.Exists(markPath); markExists == false || err != nil {
			sendResponse(w, "Image already exists", 409, nil, false)
			return
		}
	}

	writer, err := ctx.storage.StreamWrite(layerPath)
	if err != nil {
		sendResponse(w, "Couldn't write to layer file", 500, nil, false)
		return
	}

	io.Copy(writer, r.Body)

	checksumParts := strings.Split(string(checksum), ":")
	computedChecksum, err := ctx.computeImageChecksum(checksumParts[0], imageId, jsonData)
	if err != nil || computedChecksum != strings.ToLower(checksumParts[1]) {
		sendResponse(w, "Checksum mismatch, ignoring the layer", 400, nil, false)
		return
	}

	ctx.storage.Remove(markPath)

	sendResponse(w, nil, http.StatusOK, nil, false)
}

func (ctx *Context) GetImageJsonHandler(w http.ResponseWriter, r *http.Request) {
	imageId := mux.Vars(r)["imageId"]
	data, err := ctx.storage.GetContent(storage.ImageJsonPath(imageId))
	if err != nil {
		sendResponse(w, "Image not found", 404, nil, false)
		return
	}

	headers := make(map[string]string)
	if checksum, err := ctx.storage.GetContent(storage.ImageChecksumPath(imageId)); err != nil {
		headers["X-Docker-Checksum"] = string(checksum)
	}

	sendResponse(w, data, 200, headers, true)
}

func (ctx *Context) GetImageAncestryHandler(w http.ResponseWriter, r *http.Request) {
	imageId := mux.Vars(r)["imageId"]

	data, err := ctx.storage.GetContent(storage.ImageAncestryPath(imageId))
	if err != nil {
		sendResponse(w, "Image not found", 404, nil, false)
		return
	}

	sendResponse(w, data, http.StatusOK, nil, true)
}

func (ctx *Context) computeImageChecksum(algo string, imageId string, jsonData []byte) (string, error) {
	if algo != "sha256" {
		return "", fmt.Errorf("bad algorithm %s, only sha256 supported right now", algo)
	}

	hash := sha256.New()
	fmt.Fprintf(hash, "%s\n", jsonData)
	reader, err := ctx.storage.StreamRead(storage.ImageLayerPath(imageId))
	if err != nil {
		return "", fmt.Errorf("couldn't read image for checksumming", algo)
	}
	io.Copy(hash, reader)
	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

func (ctx *Context) PutImageJsonHandler(w http.ResponseWriter, r *http.Request) {
	imageId := mux.Vars(r)["imageId"]
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		sendResponse(w, "Couldn't read request body", 500, nil, false)
		return
	}

	var data map[string]string
	if err := json.Unmarshal(body, &data); err != nil {
		sendResponse(w, "Invalid JSON", 400, nil, false)
		return
	}

	if _, ok := data["id"]; !ok {
		sendResponse(w, "Missing Key `id' in JSON", 400, nil, false)
		return
	}

	checksum := r.Header.Get("X-Docker-Checksum")
	if checksum == "" {
		sendResponse(w, "Missing Image's checksum", 400, nil, false)
		return
	}

	checksumParts := strings.Split(string(checksum), ":")
	if len(checksumParts) != 2 {
		sendResponse(w, "Invalid checksum format", 400, nil, false)
		return
	}

	if checksumParts[0] != "sha256" {
		sendResponse(w, "Checksum algorithm not supported", 400, nil, false)
		return
	}

	checksumPath := storage.ImageChecksumPath(imageId)
	ctx.storage.PutContent(checksumPath, []byte(checksum))

	if imageId != data["id"] {
		sendResponse(w, "JSON data contains invalid id", 400, nil, false)
		return
	}

	parentId, ok := data["parent"]
	exists, err := ctx.storage.Exists(storage.ImageJsonPath(parentId))
	if ok && !exists && err == nil {
		sendResponse(w, "Image depends on a non existing parent", 400, nil, false)
		return
	}

	jsonPath := storage.ImageJsonPath(imageId)
	markPath := storage.ImageMarkPath(imageId)

	jsonExists, err := ctx.storage.Exists(jsonPath)
	if err != nil {
		sendResponse(w, "Couldn't check if JSON exists", 500, nil, false)
		return
	}

	markExists, err := ctx.storage.Exists(markPath)
	if err != nil {
		sendResponse(w, "Couldn't check if mark exists", 500, nil, false)
		return
	}

	if jsonExists && !markExists {
		sendResponse(w, "Image already exists", 409, nil, false)
		return
	}

	ctx.storage.PutContent(markPath, []byte("true"))
	ctx.storage.PutContent(jsonPath, body)

	if err := ctx.generateAncestry(imageId, parentId); err != nil {
		sendResponse(w, fmt.Sprintf("Couldn't generate ancestry: %s", err), 500, nil, false)
		return
	}

	sendResponse(w, nil, 200, nil, false)
}

func (ctx *Context) generateAncestry(imageId string, parentId string) error {
	if parentId == "" {
		selfAncestryJson, err := json.Marshal([]string{imageId})
		if err != nil {
			return err
		}
		if err := ctx.storage.PutContent(storage.ImageAncestryPath(imageId), selfAncestryJson); err != nil {
			return err
		}
		return nil
	}

	data, err := ctx.storage.GetContent(storage.ImageAncestryPath(parentId))
	if err != nil {
		return err
	}

	var ancestry []string
	if err := json.Unmarshal(data, &ancestry); err != nil {
		return err
	}

	newAncestry := []string{imageId}
	newAncestry = append(newAncestry, ancestry...)

	data, err = json.Marshal(newAncestry)
	if err != nil {
		return err
	}

	ctx.storage.PutContent(storage.ImageAncestryPath(imageId), data)

	return nil
}

func (ctx *Context) GetTagsHandler(w http.ResponseWriter, r *http.Request) {
	namespace := mux.Vars(r)["namespace"]
	repository := mux.Vars(r)["repository"]

	data := make(map[string]string)

	dir, err := ctx.storage.ListDirectory(storage.TagPath(namespace, repository))
	if err != nil {
		sendResponse(w, "Repository not found", 404, nil, false)
		return
	}

	for _, fname := range dir {
		tagName := filepath.Base(fname)
		if !strings.HasPrefix(tagName, "tag_") {
			continue
		}

		content, err := ctx.storage.GetContent(fname)
		if err != nil {
			continue
		}
		data[tagName[4:]] = string(content)
	}

	sendResponse(w, data, 200, nil, false)
}

func (ctx *Context) GetTagHandler(w http.ResponseWriter, r *http.Request) {
	namespace := mux.Vars(r)["namespace"]
	repository := mux.Vars(r)["repository"]
	tag := mux.Vars(r)["tag"]

	data, err := ctx.storage.GetContent(storage.TagPathWithName(namespace, repository, tag))
	if err != nil {
		sendResponse(w, "Tag not found", 404, nil, false)
		return
	}

	sendResponse(w, data, 200, nil, false)
}

func (ctx *Context) PutTagHandler(w http.ResponseWriter, r *http.Request) {
	namespace := mux.Vars(r)["namespace"]
	repository := mux.Vars(r)["repository"]
	tag := mux.Vars(r)["tag"]

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		sendResponse(w, "Couldn't read request body", 500, nil, false)
		return
	}

	var data string
	if err := json.Unmarshal(body, &data); err != nil {
		sendResponse(w, "Invalid data", 400, nil, false)
		return
	}

	exists, err := ctx.storage.Exists(storage.ImageJsonPath(data))
	if !exists || err != nil {
		sendResponse(w, "Image not found", 404, nil, false)
		return
	}

	ctx.storage.PutContent(storage.TagPathWithName(namespace, repository, tag), []byte(data))

	sendResponse(w, data, 200, nil, false)
}

func (ctx *Context) DeleteTagHandler(w http.ResponseWriter, r *http.Request) {
	namespace := mux.Vars(r)["namespace"]
	repository := mux.Vars(r)["repository"]
	tag := mux.Vars(r)["tag"]

	err := ctx.storage.Remove(storage.TagPathWithName(namespace, repository, tag))
	if err != nil {
		sendResponse(w, "Tag not found", 404, nil, false)
		return
	}

	sendResponse(w, true, 200, nil, false)
}

func (ctx *Context) DeleteRepoHandler(w http.ResponseWriter, r *http.Request) {
	namespace := mux.Vars(r)["namespace"]
	repository := mux.Vars(r)["repository"]

	err := ctx.storage.Remove(storage.TagPath(namespace, repository))
	if err != nil {
		sendResponse(w, "Repository not found", 404, nil, false)
		return
	}

	sendResponse(w, true, 200, nil, false)
}

func LoginHandler(w http.ResponseWriter, r *http.Request) {
	sendResponse(w, true, 200, nil, false)
}

func (ctx *Context) ListImagesHandler(w http.ResponseWriter, r *http.Request) {
	namespace := mux.Vars(r)["namespace"]
	repository := mux.Vars(r)["repository"]

	data, err := ctx.storage.GetContent(storage.ImageListPath(namespace, repository))
	if err != nil {
		sendResponse(w, "Repository not found", 404, nil, false)
		return
	}

	sendResponse(w, data, 200, nil, true)
}

func (ctx *Context) PutImageHandler(w http.ResponseWriter, r *http.Request) {
	namespace := mux.Vars(r)["namespace"]
	repository := mux.Vars(r)["repository"]

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		sendResponse(w, "Couldn't read request body", 500, nil, false)
		return
	}

	var data []map[string]string
	if err := json.Unmarshal(body, &data); err != nil {
		sendResponse(w, "Invalid data", 400, nil, false)
		return
	}

	ctx.storage.PutContent(storage.ImageListPath(namespace, repository), body)

	sendResponse(w, nil, 200, nil, false)
}

func sendResponse(w http.ResponseWriter, data interface{}, status int, headers map[string]string, raw bool) {
	if data == nil {
		data = true
	}

	var output []byte
	if raw == false {
		var err error
		output, err = json.Marshal(data)
		if err != nil {
			sendResponse(w, fmt.Sprintf("Couldn't marshal data to JSON: %s", err), 500, nil, false)
			return
		}
	} else {
		output = []byte(fmt.Sprintf("%s", data))
	}

	w.WriteHeader(status)
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Pragma", "no-cache")
	w.Header().Set("Expires", "-1")
	w.Header().Set("Content-Type", "application/json")

	for k, v := range headers {
		w.Header().Set(k, v)
	}

	w.Write(output)
}

func main() {
	r := mux.NewRouter()
	r.HandleFunc("/_ping", PingHandler)
	r.HandleFunc("/", HomeHandler)

	ctx := &Context{storage: &storage.Storage{RootPath: "."}}
	r.HandleFunc("/v1/images/{imageId}/layer", ctx.GetImageLayerHandler).Methods("GET")
	r.HandleFunc("/v1/images/{imageId}/layer", ctx.PutImageLayerHandler).Methods("PUT")
	r.HandleFunc("/v1/images/{imageId}/json", ctx.GetImageJsonHandler).Methods("GET")
	r.HandleFunc("/v1/images/{imageId}/json", ctx.PutImageJsonHandler).Methods("PUT")
	r.HandleFunc("/v1/images/{imageId}/ancestry", ctx.GetImageAncestryHandler).Methods("GET")

	r.HandleFunc("/v1/repositories/{namespace}/{repository}/tags", ctx.GetTagsHandler).Methods("GET")
	r.HandleFunc("/v1/repositories/{namespace}/{repository}/tags/{tag}", ctx.GetTagHandler).Methods("GET")
	r.HandleFunc("/v1/repositories/{namespace}/{repository}/tags/{tag}", ctx.PutTagHandler).Methods("PUT")
	r.HandleFunc("/v1/repositories/{namespace}/{repository}/tags/{tag}", ctx.DeleteTagHandler).Methods("DELETE")
	r.HandleFunc("/v1/repositories/{namespace}/{repository}/", ctx.DeleteRepoHandler).Methods("DELETE")

	// index stuff
	r.HandleFunc("/v1/users", LoginHandler)
	r.HandleFunc("/v1/repositories/{namespace}/{repository}/images", ctx.ListImagesHandler).Methods("GET")
	r.HandleFunc("/v1/repositories/{namespace}/{repository}/images", ctx.PutImageHandler).Methods("PUT")

	http.ListenAndServe(":8080", r)
}
