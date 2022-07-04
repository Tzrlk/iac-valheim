#!/usr/bin/env make

SHELL     := sh
MAKESHELL := sh

.ONESHELL:
.DELETE_ON_ERROR:
.ALWAYS:

include .build/*.mk
