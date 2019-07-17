vim使用指南
########################################

.. contents:: 目录

.. sectnum::

环境搭建
****************************************

依赖软件
++++++++++++++++++++++++++++++++++++++++

+ Python(Anaconda_)
+ PlantUML_\ (需要Java运行环境)
+ git_
+ IrfanView_

vim_\ 安装
++++++++++++++++++++++++++++++++++++++++

+ 下载最新的\ `gVim <https://github.com/vim/vim-win32-installer/releases>`_\ ，解压至任意路径。

+ [选做] 右键菜单添加\ vim_

.. code::

   Windows Registry Editor Version 5.00

   [HKEY_CLASSES_ROOT\*\shell\gVim]
   @="gVim"
   "Icon"="e:\\PortableSoft\\vim\\vim81\\gvim.exe,0"

   [HKEY_CLASSES_ROOT\*\shell\gVim\command]
   @="\"e:\\PortableSoft\\vim\\vim81\\gvim.exe\" --remote-silent \"%1\""

+ [选做] 将\ ``CapsLock``\ 键改成\ ``Ctrl``\ 键

.. code::

   Windows Registry Editor Version 5.00

   [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout]
   "Scancode Map"=hex:00,00,00,00,00,00,00,00,02,00,00,00,1d,00,3a,00,00,00,00,00

+ [选做] 设置\ ``HOME``\ 目录

右键“我的电脑”，添加环境变量\ ``HOME``\ ，值为一个路径，如：\ ``E:\home``\ 。

SpaceVim_\ 配置下载
++++++++++++++++++++++++++++++++++++++++

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

  - HookPreload()：对于超过100kB的文件，禁用autocomplete，可以用\ ``Ctrl+n``\ 手动激活
  - 快捷键设置

    + F5：复制（系统剪贴板）
    + F6：粘贴（系统剪贴板）
    + F7：执行\ ``#+begin_src``\ 与\ ``#+end_src``\ 之间的代码
    + F8：用外部软件打开光标所在位置的文件
    + SPC j p：展开snippet后，跳转到下一个placehoder

+ snippets

  - 自定义的snippets

插件下载与更新
++++++++++++++++++++++++++++++++++++++++

执行完上面两步之后，第一次启动\ vim_\ ，会自动使用\ git_\ 下载各种插件。

在\ vim_\ 中，\ ``Normal``\ 模式下，输入\ ``:SPUpdate``\ ，可以更新所有的插件（包含SpaceVim）。

.. _vim: https://www.vim.org
.. _SpaceVim: https://spacevim.org/cn/
.. _git: https://git-scm.com
.. _Anaconda: https://mirrors.tuna.tsinghua.edu.cn/help/anaconda/
.. _PlantUML: http://plantuml.com/zh/
.. _IrfanView: https://www.irfanview.com
