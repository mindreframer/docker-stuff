package storage

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	p "path"
	"path/filepath"
)

const REPOSITORIES = "repositories"
const IMAGES = "images"
const BUFFER_SIZE = 4096

func ImagesListPath(namespace string, repository string) string {
	return fmt.Sprintf("%s/%s/%s/_images_list", REPOSITORIES, namespace, repository)
}

func ImageJsonPath(image_id string) string {
	return fmt.Sprintf("%s/%s/json", IMAGES, image_id)
}

func ImageMarkPath(image_id string) string {
	return fmt.Sprintf("%s/%s/_inprogress", IMAGES, image_id)
}

func ImageChecksumPath(image_id string) string {
	return fmt.Sprintf("%s/%s/_checksum", IMAGES, image_id)
}

func ImageLayerPath(image_id string) string {
	return fmt.Sprintf("%s/%s/layer", IMAGES, image_id)
}

func ImageAncestryPath(image_id string) string {
	return fmt.Sprintf("%s/%s/ancestry", IMAGES, image_id)
}

func TagPath(namespace string, repository string) string {
	return fmt.Sprintf("%s/%s/%s", REPOSITORIES, namespace, repository)
}

func TagPathWithName(namespace string, repository string, tagname string) string {
	return fmt.Sprintf("%s/%s/%s/tag_%s", REPOSITORIES, namespace, repository, tagname)
}

func ImageListPath(namespace string, repository string) string {
	return fmt.Sprintf("%s/%s/%s/images", REPOSITORIES, namespace, repository)
}

type Storage struct {
	RootPath string
}

func (s *Storage) GetContent(path string) ([]byte, error) {
	return ioutil.ReadFile(p.Join(s.RootPath, path))
}

func (s *Storage) PutContent(path string, content []byte) error {
	absPath := p.Join(s.RootPath, path)
	os.MkdirAll(filepath.Dir(absPath), 0770)
	return ioutil.WriteFile(absPath, content, 0660)
}

func (s *Storage) StreamRead(path string) (io.ReadCloser, error) {
	return os.Open(p.Join(s.RootPath, path))
}

func (s *Storage) StreamWrite(path string) (io.WriteCloser, error) {
	return os.Create(p.Join(s.RootPath, path))
}

func (s *Storage) ListDirectory(path string) ([]string, error) {
	files, err := ioutil.ReadDir(p.Join(s.RootPath, path))
	if err != nil {
		return nil, err
	}

	names := make([]string, len(files))
	for i, f := range files {
		names[i] = p.Join(s.RootPath, path, f.Name())
	}
	return names, nil
}

func (s *Storage) Exists(path string) (bool, error) {
	_, err := os.Stat(p.Join(s.RootPath, path))
	if err == nil {
		return true, nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return false, err
}

func (s *Storage) Remove(path string) error {
	return os.RemoveAll(p.Join(s.RootPath, path))
}
