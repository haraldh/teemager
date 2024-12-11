# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2024 Matter Labs
{
  lib,
  pkgs,
  mkShell,
}:
mkShell {
  packages = with pkgs; [
    google-cloud-sdk-gce
  ];
}
