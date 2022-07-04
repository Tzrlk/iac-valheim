#!/usr/bin/env make

SHELL     := sh
MAKESHELL := sh

.ONESHELL:
.DELETE_ON_ERROR:
.ALWAYS:

ROOT := .

include .build/*.mk
