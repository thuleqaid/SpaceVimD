vim使用指南
########################################

.. contents:: 目录

.. sectnum::

环境搭建
****************************************

必装软件
++++++++++++++++++++++++++++++++++++++++

Python安装
========================================

+ 下载最新的\ `Anaconda3 <https://mirrors.tuna.tsinghua.edu.cn/anaconda/archive/>`_\ ，双击安装。（安装时，选择“All Users”；路径换成根目录，比如“C:\Anaconda3”。）

+ 环境变量\ ``PATH``\ 中添加Python的路径，比如：\ ``C:\Anaconda3``\ 、\ ``C:\Anaconda3\Scripts``\ 和\ ``C:\Anaconda3\Library\bin``\ 。

+ 添加环境变量\ ``PYTHONHOME``\ ，设置Python的根路径，比如：\ ``C:\Anaconda3``\ 。

+ [选做] 添加环境变量\ ``HOME``\ ，设置用户目录，比如：\ ``E:\home``\ 。

+ [选做] 创建并修改 .condarc 文件

.. code:: shell

   conda config --set show_channel_urls yes

修改文件内容：::

   channels:
     - defaults
   show_channel_urls: true
   channel_alias: http://mirrors.tuna.tsinghua.edu.cn/anaconda
   default_channels:
     - http://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
     - http://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
     - http://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
     - http://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/pro
     - http://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
   custom_channels:
     conda-forge: http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
     msys2: http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
     bioconda: http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
     menpo: http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
     pytorch: http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
     simpleitk: http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud

+ 安装python的代码格式检查库

.. code:: shell

   conda install yapf

git_\ 安装
========================================

+ 下载安装\ git_

+ [选做] 下载安装GUI前端\ `TortoiseGit <https://tortoisegit.org>`_

vim安装
++++++++++++++++++++++++++++++++++++++++

vim_\ 安装
========================================

+ 下载最新的\ `gVim <https://github.com/vim/vim-win32-installer/releases>`_\ ，解压至任意路径。（Vim采用的Python版本要与安装的一致，\ ``gvim_8.2.0080_x64.zip``\ 是对应Python3.7的最新版本。）

+ [选做] 右键菜单添加\ vim_

.. code::

   Windows Registry Editor Version 5.00

   [HKEY_CLASSES_ROOT\*\shell\gVim]
   @="gVim"
   "Icon"="e:\\PortableSoft\\vim\\vim82\\gvim.exe,0"

   [HKEY_CLASSES_ROOT\*\shell\gVim\command]
   @="\"e:\\PortableSoft\\vim\\vim82\\gvim.exe\" --remote-silent \"%1\""

+ [选做] 将\ ``CapsLock``\ 键改成\ ``Ctrl``\ 键

.. code::

   Windows Registry Editor Version 5.00

   [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout]
   "Scancode Map"=hex:00,00,00,00,00,00,00,00,02,00,00,00,1d,00,3a,00,00,00,00,00

SpaceVim_\ 配置下载
========================================

.. code:: shell

   cd %HOME%
   git clone https://github.com/SpaceVim/SpaceVim.git vimfiles
   git clone https://github.com/thuleqaid/SpaceVimD.git .SpaceVim.d

``.SpaceVim.d``\ 目录中是个人配置：

+ init.toml

  - 添加了部分插件

+ autoload/myspacevim.vim

  - 自制插件导入（et.vim）

    + g:et#bin_plantuml：plantuml.jar的路径
    + g:et#openwith：用外部软件打开光标所在位置的文件
    + g:et#bin_dot：Graphviz_\ 中dot.exe的路径（若在系统path路径中可以不用设置）

  - 自制插件导入（ip.vim）

  - HookPreload()：对于超过100kB的文件，禁用autocomplete，可以用\ ``Ctrl+n``\ 手动激活
  - 快捷键设置

    + F5：复制（系统剪贴板）
    + F6：粘贴（系统剪贴板）
    + F7：执行\ ``#+begin_src``\ 与\ ``#+end_src``\ 之间的代码
    + Shift-F7：强制执行\ ``#+begin_src``\ 与\ ``#+end_src``\ 之间的代码
    + Ctrl-F7：强制执行整个文件中\ ``#+begin_src``\ 与\ ``#+end_src``\ 之间的代码
    + F8：用外部软件打开光标所在位置的文件
    + F9：将当前文件移动到其它Vim实例中
    + SPC j p：展开snippet后，跳转到下一个placehoder

+ snippets

  - 自定义的snippets

插件下载与更新
========================================

执行完上面两步之后，第一次启动\ vim_\ ，会自动使用\ git_\ 下载各种插件。

在\ vim_\ 中，\ ``Normal``\ 模式下，输入\ ``:SPUpdate``\ ，可以更新所有的插件（包含SpaceVim）。

选装软件
++++++++++++++++++++++++++++++++++++++++

PlantUML_\ 安装
========================================

+ 下载安装\ `JRE <https://www.oracle.com/java/technologies/javase-jre8-downloads.html>`_\ （也可以按照JDK）

+ 下载并保存\ `plantuml.jar <https://plantuml.com/zh/download>`_

+ 修改\ ``~\.SpaceVim.d\autoload\myspacevim.vim``\ 文件中的\ ``g:et#bin_plantuml``

IrfanView_\ 安装
========================================

+ 下载并解压\ IrfanView_

+ 修改\ ``~\.SpaceVim.d\autoload\myspacevim.vim``\ 文件中的\ ``g:et#openwith``

Graphviz_\ 安装
========================================

+ 下载并解压\ Graphviz_

+ 环境变量\ ``PATH``\ 中添加Graphviz的路径，比如：\ ``E:\PortableSoft\graphviz\bin``\ 。

+ 添加环境变量\ ``GRAPHVIZ_DOT``\ ，设置\ ``dot.exe``\ 的路径，比如：\ ``E:\PortableSoft\graphviz\bin\dot.exe``\ 。

.. _vim: https://www.vim.org
.. _SpaceVim: https://spacevim.org/cn/
.. _git: https://git-scm.com
.. _PlantUML: http://plantuml.com/zh/
.. _IrfanView: https://www.irfanview.com
.. _Graphviz: http://www.graphviz.org
