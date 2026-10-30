#!/bin/sh
exec env NSUnbufferedIO=YES xcodebuild "$@" 2>&1
