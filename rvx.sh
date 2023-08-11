#!/usr/bin/bash
WORKDIR=$( pwd )
cd $WORKDIR
if [ ! -d $WORKDIR/old ]
then
        echo "Creating directory \"old\"..."
        mkdir $WORKDIR/old
else
        echo "Cleaning up space..."
        find $WORKDIR/old -type f -mtime +15 -delete
fi
for App in revanced-cli revanced-patches revanced-integrations
do
        echo "Checking for updates... $App"
        Latest="$App-$( curl -s https://api.github.com/repos/inotia00/$App/releases/latest | grep tag_name | awk '{print $2;}' | cut -d\" -f2 )"
        Local="revanced-$( if [ -e $WORKDIR/$App-*.jar ]; then basename $WORKDIR/$App-*.jar .jar | cut -d"-" -f2-; else echo "0"; fi )"
        if [ -n "$Latest" ] && [ "$Local" != "$Latest" ]
        then
                echo "Downloading update... $App"
                wget -q --spider $( curl -s https://api.github.com/repos/inotia00/$App/releases/latest | grep browser_download_url | if [ "$App" = "revanced-integrations" ]; then grep apk; else grep jar; fi | head -n1 | awk '{print $2;}' | cut -d\" -f2 ) && wget -q $( curl -s https://api.github.com/repos/inotia00/$App/releases/latest | grep browser_download_url | if [ "$App" = "revanced-integrations" ]; then grep apk; else grep jar; fi | head -n1 | awk '{print $2;}' | cut -d\" -f2 ) -O $WORKDIR/$Latest.jar && if [ -e $WORKDIR/$Local.jar ]
                then
                        mv $WORKDIR/$Local.jar $WORKDIR/old/
                fi
        fi
done
echo "Downloading patch list..."
wget -q $( curl -s https://api.github.com/repos/inotia00/revanced-patches/releases/latest | grep browser_download_url | grep "patches.json" | head -n1 | awk '{print $2;}' | cut -d\" -f2 ) -O $WORKDIR/patches.json
if [ ! -e $WORKDIR/patches.json ]
then
        echo "Patch list not found."
        exit 1
fi
CheckPatches=$( wc -w patches.json | awk '{print $1}'; )
if [ $CheckPatches -lt 1 ]
then
        echo "Failed to download patch list."
        exit 1
fi
UserAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
for Package in com.google.android.youtube com.google.android.apps.youtube.music
        # com.reddit.frontpage
do
        echo "Checking for updates... $Package"
        Version=$( if [ "$Package" = "com.google.android.apps.youtube.music" ]; then curl -sA "$UserAgent" "https://www.apkmirror.com/apk/google-inc/youtube-music/variant-%7B%22arches_slug%22%3A%5B%22arm64-v8a%22%5D%7D/feed/" | xmllint --xpath "(//rss/channel/item/title/text())[1]" - | cut -d" " -f3; else jq -r "[.[].compatiblePackages[] | select(.name==\"$Package\") | .versions[-1]][0]" patches.json; fi )
        LastBuild=$( if [ -e $WORKDIR/$Package-*-RVX.apk ]; then basename $WORKDIR/$Package-*-RVX.apk .apk | cut -d"-" -f2; elif [ -e $WORKDIR/$Package-*.apk ]; then basename $WORKDIR/$Package-*.apk .apk | cut -d"-" -f2; else echo "0"; fi )
        if [ -n "$Version" ] && [ "$LastBuild" != "$Version" ]
        then
                echo "Downloading update $Version... $Package"
                case $Package in
                        com.google.android.youtube)
                                Feed="https://www.apkmirror.com/apk/google-inc/youtube/variant-%7B%22dpis_slug%22%3A%5B%22nodpi%22%5D%7D/feed/"
                                WebDlUrl=$( curl -sA "$UserAgent" "$Feed" | xmllint --xpath "//rss/channel/item/link/text()" - | grep "$( echo "$Version" | sed 's/\./-/g' )" )
                                DlPageUrl=$( echo "https://www.apkmirror.com"$( curl -sA "$UserAgent" "$WebDlUrl" | grep "downloadButton" | xmllint --xpath "string(//a/@href)" - ) )
                                DdlUrl=$( echo "https://www.apkmirror.com"$( curl -sA "$UserAgent" "$DlPageUrl" | grep "download.php" | xmllint --html --xpath "string(//a/@href)" - ) )
                                wget --spider -qU "$UserAgent" "$DdlUrl" && wget -qU "$UserAgent" "$DdlUrl" -O $Package-$Version.apk && java -jar revanced-cli-*.jar -b revanced-patches-*.jar -a $Package-$Version.apk -e vanced-microg-support -m revanced-integrations-*.jar --keystore=$WORKDIR/$Package.keystore -o $Package-$Version-RVX.apk && if [ -e $Package-$LastBuild.jar ]
                                then
                                        mv $Package-$LastBuild* $WORKDIR/old/
                                fi
                                ;;
                        com.google.android.apps.youtube.music)
                                Feed="https://www.apkmirror.com/apk/google-inc/youtube-music/variant-%7B%22arches_slug%22%3A%5B%22arm64-v8a%22%5D%7D/feed/"
                                WebDlUrl=$( curl -sA "$UserAgent" "$Feed" | xmllint --xpath "(//rss/channel/item/link/text())[1]" - )
                                DlPageUrl=$( echo "https://www.apkmirror.com"$( curl -sA "$UserAgent" "$WebDlUrl" | grep "downloadButton" | xmllint --xpath "string(//a/@href)" - )
                                DdlUrl=$( echo "https://www.apkmirror.com"$( curl -sA "$UserAgent" "$DlPageUrl" | grep "download.php" | xmllint --html --xpath "string(//a/@href)" - ) )
                                wget --spider -qU "$UserAgent" "$DdlUrl" && wget -qU "$UserAgent" "$DdlUrl" -O $Package-$Version.apk && java -jar revanced-cli-*.jar -b revanced-patches-*.jar -a $Package-$Version.apk -e vanced-microg-support -m revanced-integrations-*.jar --keystore=$WORKDIR/$Package.keystore -o $Package-$Version-RVX.apk && if [ -e $Package-$LastBuild.jar ]
                                then
                                        mv $Package-$LastBuild* $WORKDIR/old/
                                fi
                                ;;
                        com.reddit.frontpage)
                                echo "Reddit not enabled."
                                ;;
                esac
                if [ -e $WORKDIR/$Package-*-RVX.apk ]
                then
                        CheckPackages=$( ls -1 $Package-*-RVX.apk | wc -l )
                        if [ $CheckPackages -gt 1 ]
                        then
                                rm $Package-$Version-RVX.apk
                                echo "Failed to build package."
                        else
                                PackageName=$( if [ "$Package" = "com.google.android.youtube" ]; then echo "YouTube"; elif [ "$Package" = "com.google.android.apps.youtube.music" ]; then echo "YouTube Music"; elif [ "$Package" = "com.reddit.frontpage" ]; then echo "Reddit"; fi )
                                echo Done! # insert your desired action here
                        fi
                else
                        echo "Failed to build package."
                fi
        elif [ -n "$Version" ] && [ ! -e $Package-$Version-RVX.apk ]
        then
                echo "Latest version wasn't patched, trying to patch it now..."
                java -jar revanced-cli-*.jar -b revanced-patches-*.jar -a $Package-$Version.apk -e vanced-microg-support -m revanced-integrations-*.jar --keystore=$WORKDIR/old/$Package-$LastBuild.keystore -o $Package-$Version-RVX.apk && mv $Package-$LastBuild.apk $WORKDIR/old/
                if [ -e $WORKDIR/$Package-*.apk ]
                then
                        CheckPackages=$( ls -1 $Package-*.apk | wc -l )
                else
                        echo "Failed to download package."
                fi
                if [ $CheckPackages -gt 1 ]
                then
                        rm $Package-$LastBuild.apk
                        echo "Failed to download update."
                else
                        PackageName=$( if [ "$Package" = "com.google.android.youtube" ]; then echo "YouTube"; elif [ "$Package" = "com.google.android.apps.youtube.music" ]; then echo "YouTube Music"; elif [ "$Package" = "com.reddit.frontpage" ]; then echo "Reddit"; fi )
                        echo Done! # insert your desired action here
                fi
        fi
done
