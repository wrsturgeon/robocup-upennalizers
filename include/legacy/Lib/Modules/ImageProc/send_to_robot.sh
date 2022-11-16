robot_ip="nao@192.168.1.120"

str_array1=(
            "ImageProc.lua"
            "File.lua"
            "nn_forward.lua"
           )

scp ${str_array1[*]} $robot_ip:~/UPennDev/Player/Lib
