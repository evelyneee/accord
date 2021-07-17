all: clean xcodebuild deb-x64 deb-arm64

xcodebuild:
	xcodebuild

deb-x64: xcodebuild
	rm -rf ./deb/Applications/*
	cp -r ./build/Release/Accord.app ./deb/Applications
	dpkg-deb -b ./deb
	mv ./deb.deb me.evelyn.accord_1.0.0_darwin-amd64.deb

deb-arm64: xcodebuild
	rm -rf deb-arm64/Applications/*
	cp -r ./build/Release/Accord.app ./deb-arm64/Applications/
	dpkg-deb -b ./deb-arm64
	mv ./deb-arm64.deb me.evelyn.accord_1.0.0_darwin-arm64.deb

zip: xcodebuild
	cd ./build/Release
	zip -vr ./Accord.app ./accord_1.0.0.zip -x .DS_Store
	cd ../../
test:
	sudo apt remove me.evelyn.accord
	sudo apt install ./me.evelyn.accord_1.0.0_$(shell dpkg --print-architecture).deb

clean:
	rm -rf ./build
	rm -rf ./*.deb

.PHONY: deb-x64 deb-arm64 clean xcodebuild
