#!/bin/bash
npm install -g cnpm --registry=https://registry.npm.taobao.org
cd /usr/local/workspace/project-dhlgl/dhl-web

cnpm build

echo "build over"
