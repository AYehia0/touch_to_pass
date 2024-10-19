build:
	rm -rf .build && rm -f main.d main.o main.swiftdeps && swift build
test:
	.build/debug/touch_to_pass get openvpn_username openvpn_password --totp openvpn

.PHONY:
	build
