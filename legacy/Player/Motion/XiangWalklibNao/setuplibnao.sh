sudo rm /home/nao/UPennDev/Player/Lib/liblibCapture.so
sudo ln -s /home/nao/UPennDev/Player/Motion/XiangWalklibNao/liblibCapture.so  /home/nao/UPennDev/Player/Lib/liblibCapture.so
sudo ln -s /home/nao/UPennDev/Player/Lib/liblibCapture.so /home/nao/local/lib/liblibCapture.so
sudo rm /home/nao/local/lib/liblibNAOWalk.so
sudo rm /home/nao/UPennDev/Player/Lib/liblibNAOWalk.so
sudo ln -s /home/nao/UPennDev/Player/Motion/XiangWalklibNao/liblibNAOWalk.so  /home/nao/UPennDev/Player/Lib/liblibNAOWalk.so
sudo ln -s /home/nao/UPennDev/Player/Motion/XiangWalklibNao/Limp /home/nao/UPennDev/Limp
sudo ln -s /home/nao/UPennDev/Player/Motion/XiangWalklibNao/Limp /home/nao/UPennDev/Player/Motion/Limp
sudo rm /home/nao/UPennDev/Player/Motion/Walk/Walk_2018Xiang_capture.lua
sudo ln -s /home/nao/UPennDev/Player/Motion/XiangWalklibNao/Walk_2018Xiang_capture.lua /home/nao/UPennDev/Player/Motion/Walk/Walk_2018Xiang_capture.lua
scp Config_NaoV4_Walk_2017.lua /home/nao/UPennDev/Player/Config/Walk
scp run_test_walk.lua /home/nao/UPennDev/Player/
sudo ldconfig
