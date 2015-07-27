#!/bin/bash

# southpark-get v0.0.2

# southpark-get - Copyright (c) PotcFdk; 2015
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function download_videos {
	URL="http://www.southpark.de/alle-episoden/s$1e$2"
	../../../youtube-dl "$URL"
}

function build_ordered_list {
	truncate --size=0 tmp-list.txt
	for FILE in *.mp4; do
		echo $FILE >> tmp-list.txt
	done
	sort tmp-list.txt -o tmp-list.txt

	# There's probably a way to do this 100% in sed.
	# Or awk. Oh well.
	INTRONAME=$(grep -i intro tmp-list.txt)
	sed -i '/intro/Id' tmp-list.txt
	echo $INTRONAME | cat - tmp-list.txt > list.txt
	rm tmp-list.txt
}

# Not Implemented
#function prepare_ffmpeg_list {
#	truncate --size=0 ffmpeg-list.txt
#	while read LINE; do
#		echo "file '$LINE'" >> ffmpeg-list.txt
#	done < list.txt
#}

#function merge_videos {
#	ffmpeg -f concat -i ffmpeg-list.txt -c copy episode.mp4
#}

function ffmpeg_fix_video {
	if [ -f "$1" ]; then
		ffmpeg -i "$1" -c copy ffmpeg-tmp.mp4 2>/dev/null
		rm -- "$1"
		mv -- ffmpeg-tmp.mp4 "$1"
	fi
}

function ffmpeg_fix_videos {
	for FILE in *.mp4; do
		#if [[ "${FILE,,}" != *"intro"* ]]; then
			echo "Processing $FILE..."
			ffmpeg_fix_video "$FILE"
		#fi
	done
}

if [ "$#" -ne 2 ]; then
	echo "Wrong number of parameters." 1>&2
	echo "Expected '$0 SEASON EPISODE' " 1>&2
	exit 1
fi

SEASON=$1
EPISODE=$2

mkdir -p southpark/s$SEASON/e$EPISODE
cd southpark/s$SEASON/e$EPISODE

if [ -f playlist.m3u ]; then
	echo "Skipping Season $SEASON Episode $EPISODE: Playlist exists."
else
	if download_videos $SEASON $EPISODE; then
		build_ordered_list
		ffmpeg_fix_videos
		mv list.txt playlist.m3u
	fi
fi
