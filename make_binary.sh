#!/bin/sh

option=$1

# 引数が１つ
if [ $# -eq 1 ]; then
    # バージョン情報を表示
    if [ $option = "-v" ]; then
	echo "Version 1.00 Junichiro Kawano"
    fi
elif [ $# -eq 0 ]; then
    if [ -e /home/junjun/Ri-one ]; then
	sudo -S rm -rf /home/junjun/Ri-one
    fi
    if [ -e /home/junjun/Ri-one.tar.gz ]; then
	sudo -S rm /home/junjun/Ri-one.tar.gz
    fi
	
    #バイナリにしたい対象をコピー
    cp -rf "/home/junjun/soccer/ri-one2019_soccer/" "/home/junjun/Ri-one"
    if [ -e /home/junjun/Ri-one ]; then
    	cd /home/junjun/Ri-one 

     	./bootstrap 
     	./configure
     	make
	
	sudo -S make distclean
	#--with-librcsc=インストール先(絶対パス)
	./configure --with-librcsc=/home/junjun/Ri-one CXXFLAGS="-O2"
		
	make
	sudo -S make install
	
	#src以外削除
	ls -a| grep -v -E 'src' | xargs rm -rf
    else
 	echo "失敗しました(1)"
	exit
    fi
	
    if [ -e /home/junjun/soccer/librcsc-4.1.0 ]; then
    	#librcsc
     	cd /home/junjun/soccer/librcsc-4.1.0/
     	sudo -S ./configure
     	sudo -S make 
     	sudo -S make install

     	sudo -S make uninstall
     	sudo -S make distclean
     	sudo -S ./configure --prefix=/home/junjun/Ri-one CXXFLAGS="-O2"
	sudo -S make
	sudo -S make install
    else
 	echo "失敗しました(2)"
	exit
    fi
     
    if [ -e /home/junjun/Ri-one/src ]; then
	#いらないファイルを削除
	cd /home/junjun/Ri-one/src

	mv data ../
	rm -rf chain_action
	rm -rf .deps
	rm *.cpp
	rm *.h
	rm *.o
	rm Make*
	rm *.sh
	rm *.sh.in
    else
 	echo "失敗しました(3)"
	exit     	
    fi
	
    if [ -e /home/junjun/Ri-one ]; then
	cd /home/junjun/Ri-one
	
     	#startスクリプト作成
     	cat << START > start
#!/bin/sh
 
HOST=$1
BASEDIR=$2
NUM=$3
	 
teamname="Ri-one"
	 
player="./src/sample_player"
coach="./src/sample_coach"
config="src/player.conf"
config_dir="src/formations-dt"
coach_config="src/coach.conf"
	 
opt="--player-config \${config} --config_dir \${config_dir}"
opt="\${opt} -h \${HOST} -t \${teamname}"
	 
coachopt="--coach-config \${coach_config}"
coachopt="\${coachopt} -h \${HOST} -t \${teamname}"
	 
cd \$BASEDIR
	 
LIBPATH=lib
if [ x"$LIBPATH" != x ]; then
    if [ x"\$LD_LIBRARY_PATH" = x ]; then
        LD_LIBRARY_PATH=$LIBPATH
    else
	LD_LIBRARY_PATH=$LIBPATH:\$LD_LIBRARY_PATH
    fi
    export LD_LIBRARY_PATH
fi
	 
case \$NUM in
	1)
	\$player \$opt -g 
	;;
	12)
    	\$coach $coachopt 
    	;;
	*)
    	\$player $opt 
    	;;
esac
START
	#killスクリプト作成
	cat << KILL > kill
#!/bin/sh

player="sample_player"
coach="sample_coach"
	 
killall -TERM \${player}
killall -TERM \${coach}
 
sleep 2
	 
killall -KILL \${player}
killall -KILL \${coach}

KILL
	#team.ymlスクリプト作成
	cat << TEAM > team.yml
---
country: jan
TEAM

	#LOCALスクリプト作成
	cat << LOCAL > local-start
#!/bin/sh
	 
HOST="localhost"
BASEDIR=`pwd`
NUM=1
	 
teamname="Ri-one"
	 
player="./src/sample_player"
coach="./src/sample_coach"
	 
config="src/player.conf"
config_dir="src/formations-dt"
coach_config="src/coach.conf"
	 
opt="--player-config \${config} --config_dir \${config_dir}"
opt="\${opt} -h \${HOST} -t \${teamname}"
	 
coachopt="--coach-config \${coach_config}"
coachopt="\${coachopt} -h \${HOST} -t \${teamname}"
	 	 
cd \$BASEDIR
	 
LIBPATH=./lib
if [ x"\$LIBPATH" != x ]; then
	if [ x"\$LD_LIBRARY_PATH" = x ]; then
	   	LD_LIBRARY_PATH=\$LIBPATH
	else
   		LD_LIBRARY_PATH=\$LIBPATH:\$LD_LIBRARY_PATH
	fi
	export LD_LIBRARY_PATH
fi
	 
while [ \$NUM -le 12 ]
do
	case \$NUM in
	     1)
	     \$player \$opt -g &
             ;;
    	     12)
	     \$coach \$coachopt &
 	     ;;
   	     *)
   	     \$player \$opt &
   	     ;;
  	esac
	sleep 0.01
	NUM=\`expr \$NUM + 1\`
done
LOCAL

	chmod +x start
	chmod +x kill
	chmod +x local-start

	tar czvf Ri-one.tar .
	mv Ri-one.tar /home/junjun/
	cd /home/junjun/
	gzip Ri-one.tar
    else
 	echo "失敗しました(4)"
	exit
    fi
    #使えなくなるので設定を戻す
    if [ -e /home/junjun/soccer/librcsc-4.1.0 ]; then
    	#librcsc
     	cd /home/junjun/soccer/librcsc-4.1.0/
     	sudo -S ./configure
     	sudo -S make 
     	sudo -S make install
    else
 	echo "失敗しました(5)"
	exit
    fi

    cd /home/junjun/
    echo "成功しました"
fi
