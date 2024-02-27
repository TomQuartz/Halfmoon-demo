#!/bin/bash

make hotel-baseline
make media-baseline
make retwis-baseline
make singleop-baseline

rm -rf ./bin/
