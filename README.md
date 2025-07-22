# wnmmp

window+nginx+mysql+mongodb+php绿色集成开发环境

#### 1、当前版本说明：


mongodb-8.0.11、mongosh-2.5.5、mysql-8.4.5、nginx-1.28.0、php-8.4.10



#### 2、运行说明

（1）php要运行需要Microsoft Visual C++运行库，可以直接点击项目bin目录里的“VC_redist.x64.exe”进行安装。

（2）确保端口没有被占用：mongodb(27017)、mysql(3306)、nginx(80)、php(9000)。

（3）点击项目目录里的start.bat启动mongodb、mysql、nginx、php等服务。

（4）点击项目目录里的stop.bat关闭mongodb、mysql、nginx、php等服务。

（5）mongodb和mysql数据库账号默认为root，密码默认为：xqkeji.cn。

（6）设置开机自动启动，可以安装为服务：右键install_service.bat“以管理员身份运行”,可以安装为服务，开机后自动运行。

（7）取消开机自动启动：右键uninstall_service.bat“以管理员身份运行”，可以取消安装的服务，下次开机不会自动运行。


