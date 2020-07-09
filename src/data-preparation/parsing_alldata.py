#!/usr/bin/env python
# coding: utf-8



path = 'data/all-playlists.json'
file = open(path, 'r')
content = []
for line in file:
    content.append(line.replace('\n', ''))
print(content[1])




print(content[4])




path2 = 'data/playlist-followers.json'
file2 = open(path2, 'r')
content = []
for line in file2:
    content.append(line.replace('\n', ''))
print(content[1])




path3 = path3 = 'data/playlist-placements.json'
file3 = open(path3, 'r')
content = []
for line in file3:
    content.append(line.replace('\n', ''))
print(content[0])




import json
import os

# Print iterations progress (from https://stackoverflow.com/questions/3173320/text-progress-bar-in-the-console)
def printProgressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 100, fill = '█'):
    """
    Call in a loop to create terminal progress bar
    @params:
        iteration   - Required  : current iteration (Int)
        total       - Required  : total iterations (Int)
        prefix      - Optional  : prefix string (Str)
        suffix      - Optional  : suffix string (Str)
        decimals    - Optional  : positive number of decimals in percent complete (Int)
        length      - Optional  : character length of bar (Int)
        fill        - Optional  : bar fill character (Str)
    """
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print('\r%s |%s| %s%% %s' % (prefix, bar, percent, suffix), end = '\r')
    # Print New Line on Complete
    if iteration == total: 
        print()

# Open file
outfn='gen/data-preparation/input/all-playlists.csv'


fn = 'data/all-playlists.json'

print("Loading " + fn + "...")
buffer = 1000


f = open(fn, 'r')
num_lines = sum(1 for line in f)
print('num lines: '+str(num_lines))

f = open(fn, 'r')
tmp_lines = f.readlines(buffer)


g=open(outfn, 'w', encoding='utf-8')

fields = ['position', 'id', 'code2', 'playlist_id', 'name', 'personalized', 'followers',
          'last_updated', 'owner_name', 'owner_id', 'user_id', 'editorial', 'fdiff_week',
          'fdiff_percent_week', 'fdiff_month', 'fdiff_percent_month',
          'genre', 'monthly_listeners', 'listeners_to_followers_ratio', 'catalog', 'active_ratio']
# Header
g.write('retrieval_unix\t'+'\t'.join(fields)+'\n')
cnt=0

print('Starting to parse')

while tmp_lines:
   #if (cnt>1000): break
   for line in tmp_lines:
        parsingobj = json.loads(line.replace('\n',''))
        
        printProgressBar(cnt, total=num_lines)
        cnt+=1
        
        for retr in parsingobj.get('retrievals'):
            if retr.get('status_code')!=200: continue
            resp = retr.get('response')
            try:
                if resp.get('obj') is None: continue
            except:
                continue
              
            for item in resp.get('obj'):
                res = []
                g.write(str(retr.get('timestamp'))+'\t')
                for it in fields:
                    try:
                        tmp=item.get(it)
                        tmp = str(tmp).replace('\t', '').replace('\n',' ')
                    except:
                        tmp = 'NA'
                    res.append(tmp)
                g.write('\t'.join(res)+'\n')
   tmp_lines = f.readlines(buffer)
   
g.close()
print('Done.')




import re

# Open file
outfn = 'gen/data-preparation/input/playlist-followers.csv'


fn = 'data/playlist-followers.json'

print("Loading " + fn + "...")
buffer = 1000


f = open(fn, 'r')
num_lines = sum(1 for line in f)
print('num lines: '+str(num_lines))

f = open(fn, 'r')
tmp_lines = f.readlines(buffer)


g=open(outfn, 'w', encoding='utf-8')

fields = ['id', 'value', 'timestp', 'daily_diff', 'interpolation']
# Header
g.write('retrieval_unix\t'+ 'playlist_id' + '\t' + '\t'.join(fields)+'\n')
cnt=0

print('Starting to parse')

while tmp_lines:
   
   for line in tmp_lines:
        parsingobj = json.loads(line.replace('\n',''))
        
        printProgressBar(cnt, total=num_lines)
        cnt+=1
        playlist_id = re.search('spotify_playlist/(.*)/spotify', parsingobj.get('url')).group(1)
        for retr in parsingobj.get('retrievals'):
            if retr.get('status_code')!=200: continue
            resp = retr.get('response')
            try:
                if resp.get('obj') is None: continue
            except:
                continue
              
            for item in resp.get('obj'):
                res = []
                g.write(str(retr.get('timestamp'))+'\t')
                for it in fields:
                    try:
                        tmp = item.get(it)
                        tmp = str(tmp).replace('\t', '').replace('\n',' ')
                    except:
                        tmp = 'NA'
                    res.append(tmp)
                g.write(playlist_id + '\t' + '\t'.join(res)+'\n')
   tmp_lines = f.readlines(buffer)
   
g.close()
print('Done.')




import json
import os
import re
import datetime 

def strToDatetime(string):
    return datetime.datetime.strptime(string, '%Y-%m-%dT%H:%M:%S.%fZ')

# Print iterations progress (from https://stackoverflow.com/questions/3173320/text-progress-bar-in-the-console)
def printProgressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 100, fill = '█'):
    """
    Call in a loop to create terminal progress bar
    @params:
        iteration   - Required  : current iteration (Int)
        total       - Required  : total iterations (Int)
        prefix      - Optional  : prefix string (Str)
        suffix      - Optional  : suffix string (Str)
        decimals    - Optional  : positive number of decimals in percent complete (Int)
        length      - Optional  : character length of bar (Int)
        fill        - Optional  : bar fill character (Str)
    """
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print('\r%s |%s| %s%% %s' % (prefix, bar, percent, suffix), end = '\r')
    # Print New Line on Complete
    if iteration == total: 
        print()
        

# Open file
outfn = 'gen/data-preparation/input/playlist-placements.csv'


fn = 'data/playlist-placements.json'

print("Loading " + fn + "...")
buffer = 1000


f = open(fn, 'r')
num_lines = sum(1 for line in f)
print('num lines: '+str(num_lines))

f = open(fn, 'r')
tmp_lines = f.readlines(buffer)


g=open(outfn, 'w', encoding='utf-8')

fields = ['track_id', 'isrc', 'position', 'removed_at', 'period', 'id', 'name', 'spotify_album_id', 
          'image_url', 'spotify_popularity', 'cm_track', 'track_genre', 'spotify_duration_ms']

# these are fields with >= 1 value
# rather than creating separate columns like artist1, artist2, values are put in the same column separated by a semicolumn
subfields = ['spotify_artist_names', 'cm_artist', 'artist_names', 'code2s', 'artist_images', 'artist_covers', 
             'spotify_artist_ids', 'spotify_track_ids', 'spotify_album_ids', 'album_ids', 'album_names', 'album_upc', 
             'album_label', 'release_dates']

audio_fields = ['key', 'mode', 'danceability', 'energy', 'speechiness', 'acousticness', 'instrumentalness', 'liveness', 
                  'valence', 'tempo', 'loudness']

# Header
g.write('retrieval_unix\t'+'playlist_id'+'\t'+'\t'.join(fields + subfields + audio_fields)+'\tadded_at\n')
cnt=0

print('Starting to parse')

while tmp_lines:
  
   for line in tmp_lines:
        parsingobj = json.loads(line.replace('\n',''))
        
        printProgressBar(cnt, total=num_lines)
        cnt+=1
        try:
            playlist_id = parsingobj.get('url').split('/')[6]
        except:
            continue
        for retr in parsingobj.get('retrievals'):
            if retr.get('status_code')!=200: continue
            resp = retr.get('response')
            try:
                if resp.get('obj') is None: continue
            except:
                continue
            for item in resp.get('obj'):
                res = []
                g.write(str(retr.get('timestamp'))+'\t')
                for it in fields:
                    try:
                        tmp = item.get(it)
                        tmp = str(tmp).replace('\t', '').replace('\n',' ')
                    except:
                        tmp = 'NA'
                    res.append(tmp)
                for it in subfields:
                    try:
                        tmp = item.get(it)
                        outlist = []
                        for i in tmp:
                            i = str(i).replace('\t', '').replace('\n',' ').replace(';', ' ')
                            outlist.append(i)
                            tmp = '; '.join(outlist)
                    except:
                        tmp = 'NA'
                    res.append(tmp)
                for it in audio_fields:
                    try:
                        tmp = item.get('audio_features').get(it)
                        tmp = str(tmp).replace('\t', '').replace('\n',' ')
                    except:
                        tmp = 'NA'
                    res.append(tmp)
                
                dates = list(map(lambda p: strToDatetime(p.get('timestp')), list(item.get('position_stats'))))
                dates.append(strToDatetime(item.get('added_at')))
                earliest = min(dates)
                res.append(earliest.isoformat())
                
                g.write(playlist_id+'\t'+'\t'.join(res)+'\n')
   tmp_lines = f.readlines(buffer)
   
g.close()
print('Done.')




import json
import os
import re
import datetime
import sys
from operator import itemgetter

def strToDatetime(string):
    return datetime.datetime.strptime(string, '%Y-%m-%dT%H:%M:%S.%fZ')

def nextDay(date):
    return date + datetime.timedelta(days=1)

# Print iterations progress (from https://stackoverflow.com/questions/3173320/text-progress-bar-in-the-console)
def printProgressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 100, fill = '█'):
    """
    Call in a loop to create terminal progress bar
    @params:
        iteration   - Required  : current iteration (Int)
        total       - Required  : total iterations (Int)
        prefix      - Optional  : prefix string (Str)
        suffix      - Optional  : suffix string (Str)
        decimals    - Optional  : positive number of decimals in percent complete (Int)
        length      - Optional  : character length of bar (Int)
        fill        - Optional  : bar fill character (Str)
    """
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print('\r%s |%s| %s%% %s' % (prefix, bar, percent, suffix), end = '\r')
    # Print New Line on Complete
    if iteration == total: 
        print()
        
LINECOUNT = 2306
# Open file
outfn = 'gen/data-preparation/input/playlist-placements-positions.csv'

fn = 'data/playlist-placements.json'

g=open(outfn, 'w', encoding='utf-8')

# Header
g.write('playlist_id'+'\t'+'track_id'+'\t'+'position'+'\t'+'added_at'+'\t'+'removed_at'+'\n')
cnt=0

print('Starting to parse')

for line in open(fn, 'r'):
    parsingobj = json.loads(line.replace('\n',''))

    printProgressBar(cnt, total=LINECOUNT)
    cnt+=1

    playlist_id = parsingobj.get('url').split('/')[6]
    for retr in parsingobj.get('retrievals'):
        if retr.get('status_code')!=200: continue
        resp = retr.get('response')
        if not resp.get('obj') is None:
            for item in resp.get('obj'):
                track_id = str(item.get('track_id'))
                if len(list(item.get('position_stats'))) == 0:
                    position = str(item.get('position'))
                    added_at = strToDatetime(item.get('added_at'))
                    if (item.get('removed_at') == None):
                        removed_at = 'NA'
                    else:
                        removed_at = strToDatetime(item.get('removed_at')).isoformat()
                    g.write(playlist_id + '\t' + track_id + '\t' + position + '\t' + added_at.isoformat() + '\t' + removed_at + '\n')
                else:
                    datePositions = []
                    datePositions.extend(map(lambda d: (strToDatetime(d.get('timestp')), str(d.get('position'))), list(item.get('position_stats'))))
                    datePositions = sorted(datePositions, key=itemgetter(0))
                    
                    added_at = strToDatetime(item.get('added_at'))
                    
                    if (datePositions[0][0] > added_at):
                        g.write(playlist_id + '\t' + track_id + '\t' + str(item.get('position')) + '\t' + added_at.isoformat() + '\t' + datePositions[0][0].isoformat() + '\n')
                    else:
                        g.write(playlist_id + '\t' + track_id + '\t' + datePositions[0][1] + '\t' + datePositions[0][0].isoformat() + '\t' + datePositions[0][0].isoformat() + '\n')
                    
                    for i in range(len(datePositions) - 1):
                        g.write(playlist_id + '\t' + track_id + '\t' + datePositions[i + 1][1] + '\t' + datePositions[i][0].isoformat() + '\t' + datePositions[i + 1][0].isoformat() + '\n')
                        
                    lastIdx = len(datePositions) - 1
                    if item.get('removed_at') == None:
                        g.write(playlist_id + '\t' + track_id + '\t' + datePositions[lastIdx][1] + '\t' + datePositions[lastIdx][0].isoformat() + '\t' + 'NA' + '\n')
                    

g.close()
print('Done.')






