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

package cmd

import (
	"github.com/pingcap-incubator/tiops/pkg/meta"
	operator "github.com/pingcap-incubator/tiops/pkg/operation"
	"github.com/pingcap-incubator/tiops/pkg/task"
	"github.com/spf13/cobra"
)

var options operator.Options

func newDestroyCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "destroy <cluster-name>",
		Short: "Destroy a specified cluster",
		RunE: func(cmd *cobra.Command, args []string) error {
			if len(args) != 1 {
				return cmd.Help()
			}

			metadata, err := meta.ClusterMetadata(args[0])
			if err != nil {
				return err
			}
			t := task.NewBuilder().
				SSHKeySet(
					meta.ClusterPath(args[0], "ssh", "id_rsa"),
					meta.ClusterPath(args[0], "ssh", "id_rsa.pub")).
				ClusterSSH(metadata.Topology, metadata.User).
				ClusterOperate(metadata.Topology, operator.StopOperation, options).
				ClusterOperate(metadata.Topology, operator.DestroyOperation, operator.Options{}).
				Build()

			return t.Execute(task.NewContext())
		},
	}
	return cmd
}
