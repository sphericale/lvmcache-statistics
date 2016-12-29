#!/bin/bash 
#
# lvmcache-statistics.sh displays the LVM cache statistics
# in a user friendly manner
#
# Copyright (C) 2014 Armin Hammer 
#
# This program is free software: you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published by 
# the Free Software Foundation, either version 3 of the License, or (at 
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
# for more details.
#
# You should have received a copy of the GNU General Public License along 
# with this program. If not, see http://www.gnu.org/licenses/.
#
# History:
# 20141220 hammerar, initial version
#
##################################################################
set -o nounset

LVCACHED=/dev/vg00/lvol0

RESULT=$(dmsetup status ${LVCACHED})
if [ $? -ne 0 ]; then
  echo "Unsuccessfull readout of <${LVCACHED}>! Abort...!"
  exit 1
fi

# http://stackoverflow.com/questions/10586153/bash-split-string-into-array
IFS=' ' read -a RESULTS <<< "${RESULT}"

##################################################################
# Reference : https://www.kernel.org/doc/Documentation/
##################################################################
#
# dmsetup status /dev/vg00/lvol1
# 0 934174720 cache 8 5178/1310720 128 963/1638400 24453 7501 5164 492458 0 8 0 \
# 1 writeback 2 migration_threshold 2048 mq 10 random_threshold 4 sequential_threshold 512 \
# discard_promote_adjustment 1 read_promote_adjustment 4 write_promote_adjustment 8

MetadataBlockSize="${RESULTS[3]}"
NrUsedMetadataBlocks="${RESULTS[4]%%/*}"
NrTotalMetadataBlocks="${RESULTS[4]##*/}"

CacheBlockSize="${RESULTS[5]}"
NrUsedCacheBlocks="${RESULTS[6]%%/*}"
NrTotalCacheBlocks="${RESULTS[6]##*/}"

NrReadHits="${RESULTS[7]}"
NrReadMisses="${RESULTS[8]}"
NrWriteHits="${RESULTS[9]}"
NrWriteMisses="${RESULTS[10]}"

NrDemotions="${RESULTS[11]}"
NrPromotions="${RESULTS[12]}"
NrDirty="${RESULTS[13]}"

INDEX=14
NrFeatureArgs="${RESULTS[${INDEX}]}"
FeatureArgs=""

if [ ${NrFeatureArgs} -ne 0 ]; then

  for ITEM in $(seq $((INDEX+1)) $((NrFeatureArgs+INDEX)) ); do
     FeatureArgs="${FeatureArgs}${RESULTS[${ITEM}]} "
  done

  INDEX=$((INDEX+NrFeatureArgs))
fi

INDEX=$((INDEX+1))
NrCoreArgs="${RESULTS[${INDEX}]}"
CoreArgs=""

if [ ${NrCoreArgs} -ne 0 ]; then

  for ITEM in $(seq $((INDEX+1)) $((NrCoreArgs+INDEX)) ); do
     CoreArgs="${CoreArgs}${RESULTS[${ITEM}]} "
  done

  INDEX=$((INDEX+NrCoreArgs))
fi

INDEX=$((INDEX+1))
PolicyName="${RESULTS[${INDEX}]}"
INDEX=$((INDEX+1))
NrPolicyArgs="${RESULTS[${INDEX}]}"
PolicyArgs=""

if [ ${NrPolicyArgs} -ne 0 ]; then

  for ITEM in $(seq $((INDEX+1)) $((NrPolicyArgs+INDEX)) ); do
     PolicyArgs="${PolicyArgs}${RESULTS[${ITEM}]} "
  done

  INDEX=$((INDEX+NrPolicyArgs))
fi

##################################################################
# human friendly output
##################################################################
echo "------------------------------------"
echo "LVM Cache report of ${LVCACHED}"
echo "------------------------------------"

MetaUsage=$( echo "scale=1;($NrUsedMetadataBlocks * 100) / $NrTotalMetadataBlocks" | bc)
CacheUsage=$( echo "scale=1;($NrUsedCacheBlocks * 100) / $NrTotalCacheBlocks" | bc)
echo "- Cache Usage: ${CacheUsage}% - Metadata Usage: ${MetaUsage}%"

ReadRate=$( echo "scale=1;($NrReadHits * 100) / ($NrReadMisses + $NrReadHits)" | bc)
WriteRate=$( echo "scale=1;($NrWriteHits * 100) / ($NrWriteMisses + $NrWriteHits)" | bc)
echo "- Read Hit Rate: ${ReadRate}% - Write Hit Rate: ${WriteRate}%"
echo "- Demotions/Promotions/Dirty: ${NrDemotions}/${NrPromotions}/${NrDirty}"
echo "- Features in use: ${FeatureArgs}"

#### EOF #########################################################

