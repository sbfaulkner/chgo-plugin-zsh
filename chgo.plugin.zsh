CHGO_VERSION="0.1.0"
GOLANGS=()

for dir in "$HOME/.golangs"; do
	[[ -d "$dir" && -n "$(ls -A "$dir")" ]] && GOLANGS+=("$dir"/*)
done
unset dir

function chgo_reset()
{
	[[ -z "$GOROOT" ]] && return

	PATH=":$PATH:"; PATH="${PATH//:$GOROOT\/bin:/:}"

	PATH="${PATH#:}"; PATH="${PATH%:}"
	unset GOROOT
	hash -r
}

function chgo_use()
{
	if [[ ! -x "$1/bin/go" ]]; then
		echo "chgo: $1/bin/go not executable" >&2
		return 1
	fi

	[[ -n "$GOROOT" ]] && chgo_reset

	export GOROOT="$1"
	export GOFLAGS="$2"
	export PATH="$GOROOT/bin:$PATH"

    export GOVERSION=$("$GOROOT/bin/go" version | awk '{ print $3 }' | sed -e 's/go//')
}

function chgo()
{
	case "$1" in
		-h|--help)
			echo "usage: chgo [GO|VERSION|system] [GOFLAGS...]"
			;;
		-V|--version)
			echo "chgo: $CHGO_VERSION"
			;;
		"")
			local dir star
			for dir in "${GOLANGS[@]}"; do
				dir="${dir%%/}"
				if [[ "$dir" == "$GOROOT" ]]; then star="*"
				else                               star=" "
				fi

				echo " $star ${dir##*/}"
			done
			;;
		system) chgo_reset ;;
		*)
			local dir match
			for dir in "${GOLANGS[@]}"; do
				dir="${dir%%/}"
				case "${dir##*/}" in
					"$1")	match="$dir" && break ;;
					*"$1"*)	match="$dir" ;;
				esac
			done

			if [[ -z "$match" ]]; then
				echo "chgo: unknown Go: $1" >&2
				return 1
			fi

			shift
			chgo_use "$match" "$*"
			;;
	esac
}

unset GOAUTOVERSION

function chgo_auto() {
	local dir="$PWD/" version

	until [[ -z "$dir" ]]; do
		dir="${dir%/*}"

		if { read -r version <"$dir/.go-version"; } 2>/dev/null || [[ -n "$version" ]]; then
			if [[ "$version" == "$GOAUTOVERSION" ]]; then return
			else
				GOAUTOVERSION="$version"
				chgo "$version"
				return $?
			fi
		fi
	done

	if [[ -n "$GOAUTOVERSION" ]]; then
		chgo_reset
		unset GOAUTOVERSION
	fi
}

if [[ ! "$preexec_functions" == *chgo_auto* ]]; then
    preexec_functions+=("chgo_auto")
fi
