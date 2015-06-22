#!/bin/bash
# this is a simple example shell script for managing a cd collection
# Copyright (C) 2015 Central South University
# Author is csucoderlee

#定義全局變量
menu_choice=""
current_cd=""
title_file="title.cdb"		#標題文件
tracks_file="tracks.cdb"	#曲目文件
temp_file=/tmp/cdb.$$		#臨時文件
trap 'rm -f $temp_file' EXIT	#中斷處理，中斷腳本程序後刪除臨時文件

#定義函數，接下來的兩個函數是工具函數
get_return(){
  echo -e "press return \c"
  read x
  return 0
}
get_confirm(){
  echo -e "are you sure? \c"
  while true
  do
    read x
    case "$x" in
      y | yes | Y | Yes | YES )
        return 0;;
      n | no | N | NO | No )
        echo
	echo "cancelled"
	return 1;;
      *) echo "please enter yes or no" ;;
    esac
  done
}

#主菜單函數
set_menu_choice(){
  clear
  echo "options :-"
  echo "   a) add new cd"
  echo "   b) find cd"
  echo "   c) count the cds and tracks in the catalog"
  if [ "$cdcatnum" != "" ]; then
    echo "   l) list tracks on $cdtitle"
    echo "   r) remove $cdtitle"
    echo "   u) update track information for $cdtitle"
  fi
  echo "   q) quit"
  echo
  echo -e "please enter choice then press return \c"
  read menu_choice
  return
}

#向數據庫文件裏添加數據
inserit_title(){
  echo $* >> $title_file
  return
}
insert_track(){
  echo $* >> $track_file
  return
}
insert_record_tracks(){
  echo "enter track information for this cd"
  echo "when no more tracks enter q"
  cdtrack=1
  cdttitle=""
  while [ "$cdttitle" != "q" ]
  do
      echo -e "track $cdtrack,track title? \c"
      read tmp
      cdttitle=${tmp%%,*}
      if [ "$tmp" != "$cdttitle" ]; then
        echo "sorry, no commas allowed"
        continue
      fi
      if [ -n "$cdttitle" ]; then
        if [ "$cdttitle" != "q" ]; then
          insert_track $cdcatnum,$cdtrack,$cdttitle
        fi
      else
        cdtrack=$((cdtrack-1))
      fi
    cdtrack=$((cdtrack+1))
  done
}

#add_records用於輸入新cd唱片的標題信息
add_records(){
  
  #prompt for the initial information

  echo -e "enter catalog name \c"
  read tmp
  cdcatnum=${tmp%%,*}

  echo -e "enter title \c"
  read tmp
  cdtitle=${tmp%%,*}

  echo -e "enter type \c"
  read tmp
  cdtype=${tmp%%,*}

  echo -e "enter artist/composer \c"
  read tmp
  cdac=${tmp%%,*}

  #覈對輸入的信息
  
  echo about to add new entry
  echo  "$cdcatnum,$cdtitle,$cdtype,$cdac"

  #如果確定輸入的信息沒有錯誤，直接插入到title文件中
  
  if get_confirm ; then
    insert_title $cdcatnum,$cdtitle,$cdtype,$cdac
    add_record_tracks
  else
    remove_records
  fi

  return  
}

#find_cd使用grep命令在唱片標題文件中查找CD唱片的相關資料
find_cd(){
  if [ "$1" = "n" ]; then
    asklist=n
  else
    asklist=y
  fi
  cdcatnum=""
  echo -e "enter a string to search for in the cd files \c"
  read searchstr
  if [ "$searchstr" = "" ]; then
    return 0
  fi

  grep "$searchstr" $title_file > $temp_file

  set $(wc -l $temp_file)
  linesfound=$1

  case "$linesfound" in
    0) echo "sorry, nothing found"
       get_return
       return 0
       ;;
    1) ;;
    2) echo "sorry, not unique."
       echo "found the following"
       cat $temp_file
       get_return
       return 0
  esac
  IFS=","
  read cdcatnum cdtitle cdtype cdac < $temp_file
  IFS=" "

  if [ -z "$cdcatnum" ]; then
    echo " sorry, could not extract catalog field from $temp_file"
    get_return
    return 0
  fi

  echo
  echo catalog number: $cdcatnum
  echo title: $cdtitle
  echo type: $cdtype
  echo artist/composer: $cdac
  echo
  get_return

  if [ "$asklist" = "y" ]; then
    echo -e "view tracks for this cd? \c"
      read x
    if [ "$x" = "y"]; then
      echo
      list_tracks
      echo
    fi
  fi
  return 1 
}

#update_cd
update_cd(){
  if [ -z "$cdcatnum" ]; then
    echo "you must select a CD first"
    find_cd n
  fi
  if [ -n "$cdcatnum" ]; then
    echo "current tracks are :-"
    list_tracks
    echo
    echo "this will re-enter the tracks for $cdtitle"
    get_confirm && {
      grep -v "^${cdcatnum}," $tracks_file > $temp_file
      mv $temp_file $tracks_file
      echo
      add_record_tracks
    }
  fi
  return
}

#count_cds
count_cds(){
  set $(wc -l $title_file)
  num_titles=$1
  set $(wc -l $tracks_file)
  num_tracks=$1
  echo found $num_titles CDs,with a total of $num_tracks tracks
  get_return
  return
}

#remove_records
remove_records(){
  if [ -z "$cdcatnum" ]; then
    echo you must select a CD first
    find_cd n
  fi
  if [ -n "$cdcatnum" ]; then
    echo "you are about to delete $cdtitle"
    get_confirm &&{
      grep -v "^${cdcatnum}," $title_file > $temp_file
      mv $temp_file $title_file
      grep -v "^{cdcatnum}," $tracks_file > $temp_file
      mv $temp_file $tracks_file
      cdcatnum=""
      echo entry removed  
    }
    get_return
  fi
  return
}

#list_tracks
list_tracks(){
  if [ "$cdcatnum" = "" ]; then
    echo no CD selected yet
    return
  else
    grep "^${cdcatnum}," $tracks_file > $temp_file
    num_tracks=$(wc -l $temp_file)
    if [ "$num_tracks" = "0" ]; then
      echo "no tracks found for $cdtitle"
    else {
      echo
      echo "$cdtitle :-"
      echo
      cut -f 2- -d, $temp_file
      echo
    } |  ${PAGER:-more}
    fi
  fi
  get_return
  return
}

#以下是主程序部分

#運行主程序之前確定不存在temp_file
#確保存在title_file
#確保存在tracks_file
rm -f $temp_file
if [ ! -f $title_file ]; then
  touch $title_file
fi
if [ ! -f $tracks_file ]; then
  touch $tracks_file 
fi

#主程序開始 
clear
echo
echo
echo "lixiang cd manager"
sleep 1

quit=n
while [ "$quit" != "y" ];
do
  set_menu_choice
  case "$menu_choice" in
    a) add_records;;
    r) remove_records;;
    f) find_cd y;;
    u) update_cd;;
    c) count_cds;;
    l) list_tracks;;
    b)
       echo
       more $title_file
       echo
       get_return;;
    q | Q ) quit=y;;
    *) echo "sorry, choice not recognezed";;
  esac
done

#tidy up and leave

rm -f $temp_file
echo "finished"
exit 0
