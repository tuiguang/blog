PATH := ./node_modules/.bin:$(PATH)
NODE_PATH := lib:$(NODE_PATH)

CHECK=\033[32m✔\033[39m
BUILD ?= public/build
JS_LIB ?= public/js/lib
CSS_FILES = $(shell find public/styles -name '*.css')
JS_FILES = $(shell find public/js -name '*.js')
JADE_FILES = $(shell find lib -name '*.jade')
STYLE_CSS ?= public/styles/style.css
BUILD_CSS = public/build/build.min.css
BUILD_JS = public/build/build.min.js

start: blog.pid tiny-lr.pid

$(STYLE_CSS): public/styles/style.styl
	@growlnotify -m "$? has changes. Compile"
	@stylus -l -u ./node_modules/nib $?


$(BUILD_CSS): $(CSS_FILES)
	@mkdir -p ${BUILD}
	@cat $^ > public/build/build.css
	@cssmin public/build/build.css > $@
	@growlnotify -m "$? has changed. Reload"
	sleep 0.500
	curl -X POST http://localhost:35729/changed -d '{ "files": "$?" }'

$(BUILD_JS): $(JS_FILES)
	@cat ${JS_LIB}/respond.js ${JS_LIB}/html5shiv.js > ${BUILD}/ie.js
	@uglifyjs ${BUILD}/ie.js > ${BUILD}/ie.min.js
	@cat ${JS_LIB}/editor.js ${JS_LIB}/highlight.pack.js ${JS_LIB}/marked.js public/js/editor.custom.js > ${BUILD}/editor.js
	@uglifyjs ${BUILD}/editor.js > ${BUILD}/editor.min.js
	@growlnotify -m "$? has changed. Reload"
	@touch $@
	sleep 0.500
	curl -X POST http://localhost:35729/changed -d '{ "files": "$?" }'

$(BUILD): $(JADE_FILES)
	@growlnotify -m "$? has changed. Reload" 
	@touch $@
	sleep 0.500
	curl -X POST http://localhost:35729/changed -d '{ "files": "index.html" }'

blog.pid:
	@mkdir -p public/upload
	@node-dev app.js &
	@echo "${CHECK} server started..."
	@sleep 0.500

tiny-lr.pid:
	@tiny-lr > /dev/null &
	@echo "${CHECK} liveload server started..."

stop-server:
	@$(shell [ -f blog.pid ] && kill `cat blog.pid`)
	@echo "${CHECK} server stopped ..."

stop-tinylr:
	@$(shell [ -f tiny-lr.pid ] && kill `cat tiny-lr.pid`)
	@echo "${CHECK} tiny-lr server stopped ..."

stop: stop-server stop-tinylr

compile: $(STYLE_CSS) $(BUILD_CSS) $(BUILD_JS) $(BUILD)

clean:
	rm -f public/build/*
	rm *.pid

.PHONY: start stop clean
