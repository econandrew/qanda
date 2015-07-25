#!/bin/sh

sqlite3 qanda.db < create_tables.sql
sqlite3 qanda.db < create_queries.sql