#!/bin/bash
wget https://npm.taobao.org/mirrors/node/v11.0.0/node-v11.0.0.tar.gz

tar -xvf node-v11.0.0.tar.gz

cd node-v11.0.0

sudo yum install gcc gcc-c++

./configure

make


sudo make install

node -v

echo "install node over"
