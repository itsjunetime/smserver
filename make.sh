#!/usr/bin/env bash

pn () {
	{ [ $# -gt 1 ] && [[ "${2}" == "-n" ]] && echo -en "${1}" >&3; } || echo -e "${1}" >&3
}

leave() {
	[ -d "${ROOTDIR}/package/SMServer.xcarchive" ] && rm -rf "${ROOTDIR}/package/SMServer.xcarchive"
	[ -d "${ROOTDIR}/package/SMServer12.xcarchive" ] && rm -rf "${ROOTDIR}/package/SMServer12.xcarchive"
	ls ./*.pem && rm key.pem cert.pem
	if ! [ "$kep" = true ]
	then
		[ -d "${ROOTDIR}/package/Payload" ] && rm -r "${ROOTDIR}/package/Payload"
		[ -d "${ROOTDIR}/package/deb/Applications" ] && rm -r "${ROOTDIR}/package/deb/Applications"
	fi

	if [ -d "${html_tmp}" ]
	then
		rm -r "${html_dir}" >&3
		mv "${html_tmp}" "${html_dir}" >&3
	fi

	exit
}

err () {
	pn "\e[31;1mERROR:\e[0m ${1}"
	leave
}

compile() {
	scheme="$1"

	pn "Compiling \e[1m$scheme\e[0m ->"

	if [ "$deb" = true ] || [ "$ipa" = true ]
	then
		pn "\e[34m==>\e[0m Checking files and LLVM Version..."
		llvm_vers=$(llvm-gcc --version | grep -oE "clang\-[0-9]{4,}" | sed 's/clang\-//g')
		[ "${llvm_vers}" -lt 1200 ] && \
			err "You are using llvm < 1200 (Xcode 11.7 or lower); this will fail to compile. Please install Xcode 12.0 or higher to build SMServer."

		{ ! [ -f "${ROOTDIR}/src/SMServer/identity.pfx" ] || ! [ -f "${ROOTDIR}/src/SMServer/shared/IdentityPass.swift" ]; } && \
			err "You haven't created some files necessary to compile this. Please run this script with the \e[1m-n\e[0m or \e[1m--new\e[0m flag first"

		if [ "$min" = true ]
		then
			! command -v minify && err "Please install minify to minify asset files"

			pn "\e[34m==>\e[0m Minifying css & html files..."
			cp -r "${html_dir}/" "${html_tmp}/"

			ls "$html_tmp"/*.css | while read -r file
			do
				newfile="${file//$(printf "%q" "$html_tmp")/$(printf "%q" "$html_dir")}"
				minify "$file" > "$newfile"
			done

			ls "$html_tmp"/*.html | while read -r file
			do
				newfile="${file//$(printf "%q" "$html_tmp")/$(printf "%q" "$html_dir")}"
				minify --html-keep-comments --html-keep-document-tags --html-keep-end-tags --html-keep-quotes --html-keep-whitespace "$file" > "$newfile"
			done
		fi

		rm -rf "${ROOTDIR}/package/$scheme.xcarchive"
		pn "\e[34m==>\e[0m Cleaning and archiving package..."
		xcodebuild clean archive -workspace "${ROOTDIR}/src/SMServer.xcworkspace" -scheme "$scheme" -archivePath "${ROOTDIR}/package/$scheme.xcarchive" -destination generic/platform=iOS -allowProvisioningUpdates | xcpretty \
			|| err "Failed to archive package. Run again with \e[1m-v\e[0m to see why"

		pn "\e[34m==>\e[0m Codesigning..."
		codesign --entitlements "${ROOTDIR}/src/app.entitlements" -f --deep -s "${DEV_CERT}" "${ROOTDIR}/package/$scheme.xcarchive/Products/Applications/$scheme.app"

		pn "✅ \e[1m$scheme.app successfully created\e[0m\n"
	fi

	if [ "$deb" = true ]
	then
		recv=false

		pn "\e[92m==>\e[0m Extracting \e[1m$scheme.app\e[0m..."
		mkdir -p "${ROOTDIR}/package/deb/Applications"
		rm -rf "${ROOTDIR}/package/deb/Applications/"*
		cp -r "${ROOTDIR}/package/$scheme.xcarchive/Products/Applications/$scheme.app" "${ROOTDIR}/package/deb/Applications/$scheme.app"

		pn "\e[92m==>\e[0m Building \e[1mlibsmserver\e[0m..."
		cd "${ROOTDIR}/libsmserver" || err "The libsmserver directory is gone."

		make -B package FINALPACKAGE=1 || err "Failed to build libsmserver. Run with the \e[1m-v\e[0m to see details"
		cd ".." || err "The parent directory is gone."

		cp "${ROOTDIR}/libsmserver/lib/libsmserver.dylib" "${ROOTDIR}/package/deb/Library/MobileSubstrate/DynamicLibraries/"
		cp "${ROOTDIR}/libsmserver/libsmserver.plist" "${ROOTDIR}/package/deb/Library/MobileSubstrate/DynamicLibraries/"

		pn "\e[92m==>\e[0m Building \e[1m.deb\e[0m..."
		dpkg -b "${ROOTDIR}/package/deb"
		{ mv "${ROOTDIR}/package/deb.deb" "${ROOTDIR}/package/${scheme}_${vers}.deb" && recv=true; } || \
			pn "\e[33;1mWARNING:\e[0m Failed to create .deb. Run with \e[1m-v\e[0m to see more details."

		if [ "$recv" = true ]
		then
			pn "✅ ${scheme}_${vers}.deb successfully created at \e[1m${ROOTDIR}/package/${scheme}_${vers}.deb\e[0m\n"
		else
			rm "${ROOTDIR}/package/${scheme}_${vers}.deb" # Since it may be corrupted
		fi
	fi

	if [ "$ipa" = true ]
	then
		pn "\e[35m==>\e[0m Extracting \e[1m$scheme.app\e[0m..."
		mkdir -p "${ROOTDIR}/package/Payload"
		rm -rf "${ROOTDIR}/package/Payload/"*
		cp -r "${ROOTDIR}/package/$scheme.xcarchive/Products/Applications/$scheme.app" "${ROOTDIR}/package/Payload/$scheme.app"

		pn "\e[35m==>\e[0m Compressing payload into \e[1m${scheme}_${vers}.ipa\e[0m..."
		ditto -c -k --sequesterRsrc --keepParent "${ROOTDIR}/package/Payload" "${ROOTDIR}/package/${scheme}_${vers}.ipa"

		pn "✅ ${scheme}_${vers}.ipa successfully created at \e[1m${ROOTDIR}/package/${scheme}_${vers}.ipa\e[0m"
	fi
}

OLDDIR="$(pwd)"
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[[ "$OLDDIR" == "$ROOTDIR" ]] && ROOTDIR="."

html_dir="${ROOTDIR}/src/SMServer/html"
html_tmp="${ROOTDIR}/src/SMServer/tmp_html"

vers=$(grep "Version" "${ROOTDIR}/package/deb/DEBIAN/control" | cut -d " " -f2)
new=false
deb=false
ipa=false
vbs=false
hlp=false
kep=false
min=false
low=false

stty -echoctl
trap 'leave' SIGINT

for arg in "$@"
do
	ng=$(echo "$arg" | cut -d "-" -f2-)
	if [[ "${ng:0:1}" == "-" ]]
	then
		[[ "${ng}" == "-new" ]] && new=true
		[[ "${ng}" == "-deb" ]] && deb=true
		[[ "${ng}" == "-ipa" ]] && ipa=true
		[[ "${ng}" == "-help" ]] && hlp=true
		[[ "${ng}" == "-keep" ]] && kep=true
		[[ "${ng}" == "-verbose" ]] && vbs=true
		[[ "${ng}" == "-minify" ]] && min=true
		[[ "${ng}" == "-lower" ]] && low=true
	else
		for ((i=0; i<${#ng}; i++))
		do
			[[ "${ng:$i:1}" == "n" ]] && new=true
			[[ "${ng:$i:1}" == "d" ]] && deb=true
			[[ "${ng:$i:1}" == "i" ]] && ipa=true
			[[ "${ng:$i:1}" == "v" ]] && vbs=true
			[[ "${ng:$i:1}" == "h" ]] && hlp=true
			[[ "${ng:$i:1}" == "k" ]] && kep=true
			[[ "${ng:$i:1}" == "m" ]] && min=true
			[[ "${ng:$i:1}" == "l" ]] && low=true
		done
	fi
done

{ [ "$vbs" = true ] && exec 3>&1; } || exec 3>&1 &>/dev/null

[[ "$(uname)" == "Darwin" ]] || err "This can only be run on MacOS"

if [ "$hlp" = true ] || { [ "$deb" != true ] && [ "$ipa" != true ] && [ "$new" != true ]; }
then
	pn "
    usage: ./make.sh -hndivk

    \e[1mOptions\e[0m:
        -h, --help    : Shows this help message; ignores all other options
        -n, --new     : Runs processes that only need to happen once, specifically creating a certificate
                        and adding support swift files. You must run this at least once after cloning the
                        repo or else it won't build.
        -d, --deb     : Builds a .deb. Requires either the command line utility \e[1mdpkg\e[0m, or a jailbroken
                        iDevice on the local network to ssh into to create the archive
        -i, --ipa     : Builds a .ipa
        -v, --verbose : Runs verbose; doesn't hide any output
        -k, --keep    : Don't remove extracted \e[1mSMServer.app\e[0m files when cleaning up
        -m, --minify  : Minify css & html file when compiling assets using minify (\e[1mbrew install tdewolff/tap/minify\e[0m)
        -l, --lower   : Compile the CLI version as well, for iOS 12 & lower
    "
	exit
fi

! command -v xcodebuild &>/dev/null && err "Please install xcode command line tools"

[ "$new" = true ] && ! command -v openssl &> /dev/null && err "Please install \e[1mopenssl\e[0m (required to build new certificates)"
[ "$deb" = true ] && ! command -v dpkg &>/dev/null && err "Please install dpkg to create deb pagkage"

ls -A "${ROOTDIR}"/libsmserver/* || err "It looks like you haven't yet set up this repository's submodules. Please run \e[1mgit submodule init && git submodule update --remote\e[0m and try again."

[ -z ${DEV_CERT+x} ] && DEV_CERT=$(security find-identity -v -p codesigning | head -n1 | cut -d '"' -f2)

if [ "$new" = true ]
then
	pn "\n\e[33mWARNING:\e[0m Running this with the \e[1m-n\e[0m flag will delete the existing \e[1mcert.der\e[0m file and replace it with one you will be creating."
	pn "This is necessary to build from source. If you'd like to continue, hit enter. Else, cancel execution of this script\n"
	pn "These new certificates will need a password to function correctly, which you'll need to provide."

	pn "Please enter it here: " -n
	read -r pass
	pn "Please enter again for verification: " -n
	read -r passcheck

	while ! [[ "${pass}" == "${passcheck}" ]]
	do
		pn "\n\e[33mWARNING:\e[0m passwords are not equal. Please try again."
		pn "Please enter the password: " -n
		read -r pass
		pn "Please enter again for verification: " -n
		read -r passcheck
	done

	pn "\e[35m==>\e[0m Creating certificate..."
	openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 9999 -nodes -subj "/C=ZZ/ST=./L=./O=./CN=smserver.com"
	openssl x509 -outform der -in cert.pem -out "${ROOTDIR}/src/SMServer/cert.der"
	openssl pkcs12 -export -out "${ROOTDIR}/src/SMServer/identity.pfx" -inkey key.pem -in cert.pem -password pass:"$pass"

	rm key.pem cert.pem

	echo -en "class PKCS12Identity {\n\tstatic let pass: String = \"${pass}\"\n}" > ${ROOTDIR}/src/SMServer/shared/IdentityPass.swift

	olddir="$(pwd)"
	cd "${ROOTDIR}/src" || err "Source directory is gone"
	pn "\e[35m==>\e[0m Installing pods..."

	pod update Criollo --no-repo-update
	pod install

	cd "$olddir" || err "$olddir is gone"
	pn "" # for the newline
fi

compile "SMServer"

[ "$low" = true ] && pn "" && compile "SMServer12"

leave
