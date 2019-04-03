#!/bin/sh

option=$1

# 引数が１つ
if [ $# -eq 1 ]; then
    # バージョン情報を表示
    if [ $option = "-v" ]; then
	echo "Version 1.03 Junichiro Kawano"
    fi
elif [ $# -eq 0 ]; then
    if [ -e /home/junjun/Agent ]; then
	sudo -S rm -rf /home/junjun/Agent
    fi
    if [ -e /home/junjun/Agent.tar.gz ]; then
	sudo -S rm /home/junjun/Agent.tar.gz
    fi
	
    #バイナリにしたい対象をコピー
    cp -rf "/home/junjun/soccer/agent2d-3.1.1/" "/home/junjun/Agent"
    if [ -e /home/junjun/Agent ]; then
    	cd /home/junjun/Agent 

     	./bootstrap 
     	./configure
     	make
	
	sudo -S make distclean
	#--with-librcsc=インストール先(絶対パス)
	./configure --with-librcsc=/home/junjun/Agent CXXFLAGS="-O2"
		
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
     	sudo -S ./configure --prefix=/home/junjun/Agent CXXFLAGS="-O2"
	sudo -S make
	sudo -S make install
    else
 	echo "失敗しました(2)"
	exit
    fi
     
    if [ -e /home/junjun/Agent/src ]; then
	#いらないファイルを削除
	cd /home/junjun/Agent/src

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
	
    if [ -e /home/junjun/Agent ]; then
	cd /home/junjun/Agent
	
     	#startスクリプト作成
     	cat << START > start
#!/bin/sh
 
HOST=\$1
BASEDIR=\$2
NUM=\$3
	 
teamname="Agent"
	 
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
if [ x"\$LIBPATH" != x ]; then
    if [ x"\$LD_LIBRARY_PATH" = x ]; then
        LD_LIBRARY_PATH=\$LIBPATH
    else
	LD_LIBRARY_PATH=\$LIBPATH:\$LD_LIBRARY_PATH
    fi
    export LD_LIBRARY_PATH
fi
	 
case \$NUM in
	1)
	\$player \$opt -g 
	;;
	12)
    	\$coach \$coachopt 
    	;;
	*)
    	\$player \$opt 
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
BASEDIR=\`pwd\`
NUM=1
	 
teamname="Agent"
	 
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

	tar czvf Agent.tar .
	mv Agent.tar /home/junjun/
	cd /home/junjun/
	gzip Agent.tar
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
