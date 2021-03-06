// Copyright 2020 PingCAP, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// See the License for the specific language governing permissions and
// limitations under the License.

package scripts

import (
	"bytes"
	"io/ioutil"
	"os"
	"path"
	"text/template"

	"github.com/pingcap-incubator/tiup/pkg/localdata"
)

// TiDBScript represent the data to generate TiDB config
type TiDBScript struct {
	IP         string
	Port       uint64
	StatusPort uint64
	DeployDir  string
	NumaNode   string
	Endpoints  []*PDScript
}

// NewTiDBScript returns a TiDBScript with given arguments
func NewTiDBScript(ip, deployDir string) *TiDBScript {
	return &TiDBScript{
		IP:         ip,
		Port:       4000,
		StatusPort: 10080,
		DeployDir:  deployDir,
	}
}

// WithPort set Port field of TiDBScript
func (c *TiDBScript) WithPort(port uint64) *TiDBScript {
	c.Port = port
	return c
}

// WithStatusPort set StatusPort field of TiDBScript
func (c *TiDBScript) WithStatusPort(port uint64) *TiDBScript {
	c.StatusPort = port
	return c
}

// WithNumaNode set NumaNode field of TiDBScript
func (c *TiDBScript) WithNumaNode(numa string) *TiDBScript {
	c.NumaNode = numa
	return c
}

// AppendEndpoints add new PDScript to Endpoints field
func (c *TiDBScript) AppendEndpoints(ends ...*PDScript) *TiDBScript {
	c.Endpoints = append(c.Endpoints, ends...)
	return c
}

// Config read ${localdata.EnvNameComponentInstallDir}/templates/scripts/run_tidb.sh.tpl as template
// and generate the config by ConfigWithTemplate
func (c *TiDBScript) Config() ([]byte, error) {
	fp := path.Join(os.Getenv(localdata.EnvNameComponentInstallDir), "templates", "scripts", "run_tidb.sh.tpl")
	tpl, err := ioutil.ReadFile(fp)
	if err != nil {
		return nil, err
	}
	return c.ConfigWithTemplate(string(tpl))
}

// ConfigToFile write config content to specific path
func (c *TiDBScript) ConfigToFile(file string) error {
	config, err := c.Config()
	if err != nil {
		return err
	}
	return ioutil.WriteFile(file, config, 0755)
}

// ConfigWithTemplate generate the TiDB config content by tpl
func (c *TiDBScript) ConfigWithTemplate(tpl string) ([]byte, error) {
	tmpl, err := template.New("TiDB").Parse(tpl)
	if err != nil {
		return nil, err
	}

	content := bytes.NewBufferString("")
	if err := tmpl.Execute(content, c); err != nil {
		return nil, err
	}

	return content.Bytes(), nil
}
