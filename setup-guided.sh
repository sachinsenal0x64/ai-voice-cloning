#!/bin/bash

if ! command -v git &> /dev/null; then
	if [[ "$(read -e -p 'Could not find git. Continue? [y/N]> '; echo $REPLY)" != [Yy]* ]]; then exit 1; fi
else
	printf "git - ok\n"
fi

# TODO: This could be more precise. e.g. checking for python3, then python, etc.
if ! command -v python &> /dev/null; then
	if [[ "$(read -e -p 'Could not find python. Continue? [y/N]> '; echo $REPLY)" != [Yy]* ]]; then exit 1; fi
else
	python -c 'import sys; sys.stderr.write("Wrong python version.\n") if sys.version_info.major != 3 else sys.stderr.write("Python 3 - ok\n")'
fi

printf "Which GPU brand do you have?\n"
gpus=(nvidia amd)

gpu=""
while [ "$gpu" = "" ]; do
	select gpu in $(printf '%s\n' ${gpus[@]}); do break; done
done

if [ $gpu = "nvidia" ]; then
	./setup-cuda.sh
elif [ $gpu = "amd" ]; then
	./setup-rocm.sh
fi

source ./venv/bin/activate

printf "Which Whisper backend would you like to use?\n"
whisper_backends=("openai/whisper" "m-bain/whisperx" "lightmare/whispercpp")

whisper_backend=""
while [ "$whisper_backend" = "" ]; do
	select whisper_backend in $(printf '%s\n' ${whisper_backends[@]}); do break; done
done

if [ $whisper_backend = "openai/whisper" ]; then
	python -m pip install git+https://github.com/openai/whisper.git
elif [ $whisper_backend = "m-bain/whisperx" ]; then
	python -m pip install git+https://github.com/m-bain/whisperx.git
elif [ $whisper_backend = "lightmare/whispercpp" ]; then
	# This depends on SemVer
	# Git > v2.18 for `--sort`
	# Git > v2.4 for `versionsort.suffix`
	# For older versions:
	# git ls-remote --refs --tags https://git.ecker.tech/lightmare/whispercpp.py | cut --delimiter='/' --fields=3 | tr '-' '~' | sort --version-sort | tail --lines=1
	WHISPERCPP_LATEST=$(git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags https://git.ecker.tech/lightmare/whispercpp.py '*.*.*' | tail -n 1 | cut --delimiter='/' --fields=3)
	python -m pip install git+https://git.ecker.tech/lightmare/whispercpp.py@$WHISPERCPP_LATEST
fi

deactivate
