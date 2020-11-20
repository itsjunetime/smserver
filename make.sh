#!/bin/bash

pn () {
	([ $# -gt 1 ] && [[ "${2}" == "-n" ]] && echo -en "${1}" >&3) || echo -e "${1}" >&3
}

leave() {
	[ -d ${ROOTDIR}/package/SMServer.xcarchive ] && rm -rf ${ROOTDIR}/package/SMServer.xcarchive
	[ "$(ls | grep '.pem')" ] && rm key.pem cert.pem
	if ! [ "$kep" = true ]
	then
		[ -d ${ROOTDIR}/package/Payload ] && rm -r ${ROOTDIR}/package/Payload
		[ -d ${ROOTDIR}/package/deb/Applications ] && rm -r ${ROOTDIR}/package/deb/Applications
	fi
	exit
}

err () {
	pn "\033[31;1mERROR:\033[0m ${1}"
	leave
}

OLDDIR="$(pwd)"
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[[ "$OLDDIR" == "$ROOTDIR" ]] && ROOTDIR="."

vers=$(cat ${ROOTDIR}/package/deb/DEBIAN/control | grep "Version" | cut -d " " -f2)
new=false
deb=false
ipa=false
vbs=false
hlp=false
kep=false

for arg in "$@"
do
	ng=$(echo $arg | cut -d "-" -f2-)
	if [[ "${ng:0:1}" == "-" ]]
	then
		[[ "${ng}" == "-new" ]] && new=true
		[[ "${ng}" == "-deb" ]] && deb=true
		[[ "${ng}" == "-ipa" ]] && ipa=true
		[[ "${ng}" == "-help" ]] && hlp=true
		[[ "${ng}" == "-keep" ]] && kep=true
		[[ "${ng}" == "-verbose" ]] && vbs=true
	else
		for ((i=0; i<${#ng}; i++))
		do
			[[ "${ng:$i:1}" == "n" ]] && new=true
			[[ "${ng:$i:1}" == "d" ]] && deb=true
			[[ "${ng:$i:1}" == "i" ]] && ipa=true
			[[ "${ng:$i:1}" == "v" ]] && vbs=true
			[[ "${ng:$i:1}" == "h" ]] && hlp=true
			[[ "${ng:$i:1}" == "k" ]] && kep=true
		done
	fi
done

[ "$vbs" = true ] && exec 3>&1 || exec 3>&1 &>/dev/null

[[ "$(uname)" == "Darwin" ]] || err "This can only be run on MacOS"

if [ "$hlp" = true ] || ([ "$deb" != true ] && [ "$ipa" != true ])
then
	pn "
    usage: ./make.sh -hndivk

    \033[1mOptions\033[0m:
        -h, --help    : Shows this help message; ignores all other options
        -n, --new     : Runs processes that only need to happen once, specifically creating a certificate
                        and adding support swift files. You must run this at least once after cloning the
                        repo or else it won't build.
        -d, --deb     : Builds a .deb. Requires a jailbroken iDevice on the local network to ssh into to
                        create the archive
        -i, --ipa     : Builds a .ipa
        -v, --verbose : Runs verbose; doesn't hide any output
        -k, --keep    : Don't remove extracted \033[1mSMServer.app\033[0m files when cleaning up
    "
	exit
fi

! command -v xcodebuild &>/dev/null && err "Please install xcode command line tools"

[ "$new" = true ] && ! command -v openssl &> /dev/null && err "Please install \033[1mopenssl\033[0m (required to build new certificates)"

[ -z ${DEV_CERT+x} ] && DEV_CERT=$(security find-identity -v -p codesigning | head -n1 | cut -d '"' -f2)

if [ "$new" = true ]
then
	pn "\n\033[33mWARNING:\033[0m Running this with the \033[1m-n\033[0m flag will delete the existing \033[1mcert.der\033[0m file and replace it with one you will be creating."
	pn "This is necessary to build from source. If you'd like to continue, hit enter. Else, cancel execution of this script\n"
	pn "These new certificates will need a password to function correctly, which you'll need to provide."

	pn "Please enter it here: " -n
	read pass
	pn "Please enter again for verification: " -n
	read passcheck

	while ! [[ "${pass}" == "${passcheck}" ]]
	do
		pn "\n\033[33mWARNING:\033[0m passwords are not equal. Please try again."
		pn "Please enter the password: " -n
		read pass
		pn "Please enter again for verification: " -n
		read passcheck
	done

	pn "\033[35m==>\033[0m Creating certificate..."
	openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 9999 -nodes -subj "/C=ZZ/ST=./L=./O=./CN=smserver.com"
	openssl x509 -outform der -in cert.pem -out ${ROOTDIR}/src/SMServer/cert.der
	openssl pkcs12 -export -out ${ROOTDIR}/src/SMServer/identity.pfx -inkey key.pem -in cert.pem -password pass:${pass}

	rm key.pem cert.pem

	echo -en "class PKCS12Identity {\n\tstatic let pass: String = \"${pass}\"\n}" > ${ROOTDIR}/src/SMServer/IdentityPass.swift
fi

if [ "$deb" = true ] || [ "$ipa" = true ]
then
	rm -rf ${ROOTDIR}/package/SMServer.xcarchive
	pn "\033[34m==>\033[0m Clean building package..."
	xcodebuild clean build -workspace ${ROOTDIR}/src/SMServer.xcworkspace -scheme SMServer -destination generic/platform=iOS

	[ $? -ne 0 ] && err "Failed to build package. Run again with \033[1m-v\033[0m to see why"

	pn "\033[34m==>\033[0m Archiving package..."
	xcodebuild archive -workspace ${ROOTDIR}/src/SMServer.xcworkspace -scheme SMServer -archivePath ${ROOTDIR}/package/SMServer.xcarchive -destination generic/platform=iOS

	pn "\033[34m==>\033[0m Codesigning..."
	codesign --entitlements ${ROOTDIR}/src/app.entitlements -f -s "${DEV_CERT}" ${ROOTDIR}/package/SMServer.xcarchive/Products/Applications/SMServer.app

	pn "✅ \033[1mSMServer.app successfully created\033[0m\n"
fi

if [ "$deb" = true ]
then
	recv=false

	pn "\033[92m==>\033[0m Extracting \033[1mSMServer.app\033[0m..."
	mkdir -p ${ROOTDIR}/package/deb/Applications
	rm -rf ${ROOTDIR}/package/deb/Applications/SMServer.app
	cp -r ${ROOTDIR}/package/SMServer.xcarchive/Products/Applications/SMServer.app ${ROOTDIR}/package/deb/Applications/SMServer.app

	if command -v dpkg &>/dev/null
	then
		pn "\033[92m==>\033[0m Building \033[1m.deb\033[0m..."
		dpkg -b ${ROOTDIR}/package/deb
		mv ${ROOTDIR}/package/deb.deb ${ROOTDIR}/package/SMServer_${vers}.deb

		[ $? -eq 0 ] && recv=true
		[ $? -ne 0 ] && pn "\033[33mWARNING:\033[0m Failed to create .deb. Run with \033[1m-v\033[0m to see more details."
	else

		pn "\nSince you don't have \033[1mdpkg\033[0m installed, we must send the .app package over to your iDevice to create the \033[1m.deb\033[0m package."
		pn "Doing that now...\n"

		! command -v sshpass &> /dev/null && err "sshpass is not installed on this computer. You can install it with \033[1mbrew install hudochenkov/sshpass/sshpass\033[0m"

		if [ -z ${THEOS_DEVICE_IP+x} ]
		then
			pn "Please enter your iDevice's \033[1mIP address\033[0;34m: " -n
			read THEOS_DEVICE_IP
		fi

		if [ -z ${THEOS_DEVICE_PASS+x} ]
		then
			pn "\033[0mPlease enter your iDevice's \033[1mssh password\033[0;34m: " -n
			read -s THEOS_DEVICE_PASS
			echo "" # Just for the newline
		fi


		pn "\033[92m==>\033[0m Removing old directory and sending over new files..."
		sshpass -p $THEOS_DEVICE_PASS ssh root@${THEOS_DEVICE_IP} rm -rf /var/mobile/Documents/SMServer

		[ $? -ne 0 ] && err "Failed to ssh into your iDevice. Please check your connection and try again. Exiting..."

		sshpass -p $THEOS_DEVICE_PASS scp -Crp ${ROOTDIR}/package/deb root@${THEOS_DEVICE_IP}:/var/mobile/Documents/SMServer

		pn "\033[92m==>\033[0m Creating new package..."
		sshpass -p $THEOS_DEVICE_PASS ssh root@${THEOS_DEVICE_IP} dpkg -b /var/mobile/Documents/SMServer

		while ! [ "$recv" = true ]
		do
			pn "\033[92m==>\033[0m Receiving new package..."
			sshpass -p $THEOS_DEVICE_PASS scp -C root@${THEOS_DEVICE_IP}:/var/mobile/Documents/SMServer.deb ${ROOTDIR}/package/SMServer_${vers}.deb

			if [ $? -eq 0 ]
			then
				recv=true
				break
			fi

			pn "\033[1;33mWARNING:\033[0m Failed to receive new package over scp.\n"
			pn "Would you like to retry? [y/n]: " -n
			read -n1 cont

			([[ "${cont}" == "n" ]] || [[ "${cont}" == "N" ]]) && break

		done
	fi

	if [ "$recv" = true ]
	then
		pn "✅ SMServer_${vers}.deb successfully created at \033[1m${ROOTDIR}/package/SMServer_${vers}.deb\033[0m\n"
	else
		pn "\033[1;33mWARNING:\033[0m Could not receive package over scp.\n"
		rm ${ROOTDIR}/package/SMServer_${vers}.deb # Since it may be corrupted
	fi
fi

if [ "$ipa" = true ]
then
	pn "\033[35m==>\033[0m Extracting \033[1mSMServer.app\033[0m..."
	mkdir -p ${ROOTDIR}/package/Payload
	rm -rf ${ROOTDIR}/package/Payload/SMServer.app
	cp -r ${ROOTDIR}/package/SMServer.xcarchive/Products/Applications/SMServer.app ${ROOTDIR}/package/Payload/SMServer.app

	pn "\033[35m==>\033[0m Compressing payload into \033[1mSMServer_${vers}.ipa\033[0m..."
	ditto -c -k --sequesterRsrc --keepParent ${ROOTDIR}/package/Payload/SMServer.app ${ROOTDIR}/package/SMServer.zip
	mv ${ROOTDIR}/package/SMServer.zip ${ROOTDIR}/package/SMServer_${vers}.ipa

	pn "✅ SMServer_${vers}.ipa successfully created a† \033[1m${ROOTDIR}/package/SMServer_${vers}.ipa\033[0m"
fi

leave
