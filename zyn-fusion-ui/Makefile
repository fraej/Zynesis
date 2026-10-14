# Build the Zyn-Fusion runtime library (libzest) that the plugin editor loads.
#
#   make linux     libzest.so, with the native toolchain
#   make windows   libzest.dll; set CC, CXX and AR to the MinGW-w64 tools
#
# Both build in-tree and share mruby/build, so run `make clean` when
# switching platforms.

linux:
	ruby ./rebuild-fcache.rb
	cd deps/nanovg/src   && $(CC) nanovg.c -c -fPIC
	$(AR) rc deps/libnanovg.a deps/nanovg/src/*.o
	cd deps/mruby-file-stat/src && ../configure
	cd src/osc-bridge    && make lib
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake
	$(CC) -shared -o libzest.so `find mruby/build/host -type f | grep -v mrbc | grep -e "\.o$$" | grep -v bin` ./deps/libnanovg.a \
		./deps/libnanovg.a \
		src/osc-bridge/libosc-bridge.a \
		$(CFLAGS) \
		`pkg-config --libs libuv` -lm -lX11 -lGL -lpthread \
		$(LDFLAGS)

windows: deps/libuv-win.a
	ruby ./rebuild-fcache.rb
	cd deps/nanovg/src   && $(CC) -mstackrealign nanovg.c -c
	$(AR) rc deps/libnanovg.a deps/nanovg/src/*.o
	cd src/osc-bridge    && CFLAGS="-mstackrealign -I ../../deps/libuv/include " make lib
	cd mruby             && WINDOWS=1 MRUBY_CONFIG=../build_config.rb rake
	$(CC) -mstackrealign -shared -o libzest.dll -static-libgcc `find mruby/build/w64 -type f | grep -e "\.o$$" | grep -v bin` \
		./deps/libnanovg.a \
		src/osc-bridge/libosc-bridge.a \
		./deps/libuv-win.a \
		-lm -lpthread -lws2_32 -lkernel32 -lpsapi -luserenv -liphlpapi -lglu32 -lgdi32 -lopengl32

deps/libuv-win.a:
	cd deps/libuv   && ./autogen.sh
	cd deps/libuv   && CC="" CCLD="" CXX="" AR="" LD="" CFLAGS="-mstackrealign" ./configure  --host=x86_64-w64-mingw32 --disable-shared --enable-static
	cd deps/libuv   && CC="" CCLD="" CXX="" AR="" LD=x86_64-w64-mingw32-gcc make
	cp deps/libuv/.libs/libuv.a deps/libuv-win.a

clean:
	rm -rf mruby/build package
	rm -f libzest.so libzest.dll deps/libnanovg.a deps/libuv-win.a deps/nanovg/src/*.o
	cd src/osc-bridge && make clean

.PHONY: linux windows clean
