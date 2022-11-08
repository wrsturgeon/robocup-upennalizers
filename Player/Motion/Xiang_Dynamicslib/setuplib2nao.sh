sudo rm /home/nao/local/lib/libGetupEngine.so
sudo ln -s /home/nao/UPennDev/Player/Motion/Xiang_Dynamicslib/libGetupEngine.so /home/nao/local/lib/libGetupEngine.so
sudo rm /home/nao/UPennDev/Player/Lib/libnaodynamicsDX.so
sudo ln -s /home/nao/UPennDev/Player/Motion/Xiang_Dynamicslib/libnaodynamicsDX.so /home/nao/UPennDev/Player/Lib/libnaodynamicsDX.so
sudo rm /home/nao/local/lib/librbdl.so.2.5.0
sudo ln -s /home/nao/UPennDev/Player/Motion/Xiang_Dynamicslib/librbdl.so.2.5.0 /home/nao/local/lib/librbdl.so.2.5.0
sudo rm /home/nao/local/lib/librbdl_urdfreader.so.2.5.0
sudo ln -s /home/nao/UPennDev/Player/Motion/Xiang_Dynamicslib/librbdl_urdfreader.so.2.5.0 /home/nao/local/lib/librbdl_urdfreader.so.2.5.0
sudo ldconfig
