---
title: "配置Vim开发环境"
date: 2017-10-29T21:51:29+08:00
categories:
- Linux
tags:
- Development
- Vim
- Linux
---

配置一个优秀个开发环境可以极大地提高开发效率，在Linux里Vim是最常用的开发环境之一（emacs也是相当不错的，但鄙人是Vim的忠实粉丝），我们一般所说的开发环境包括了

- 代码高亮
- 文件树
- 配色方案
- 自动缩进
- 代码补全

这里就Linux中配置这些功能做一个简单的介绍

<!--more-->

Vim中配置这些功能主要分为两种方式：1. 安装插件; 2. 修改配置文件。所以第一件事就是安装插件管理器，因为以后所有的插件都将通过它来安装

## 插件管理器：vundle
vim中很多软件可以通过vundle安装，简化了插件的安装过程，vundle的安装也十分简单。</br>
项目主页：<https://github.com/VundleVim/Vundle.vim>
### 安装vundle
在命令行中输入
```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```
### 配置vundle
在`~/.vimrc`文件顶部输入一下代码，配置vundle

```Vim
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'

" 这里放置其他插件
" 格式为 Plugin 'username/Plugin_name'

call vundle#end()            " required
filetype plugin indent on    " required
```

### 安装插件
在刚才输入的代码段`call vundle#begin()`和`call vundle#end() `之间放置插件，插入以下代码。

```vim
Plugin 'git_name/plugin_name'
```
> Note: `git_name`是该插件github的用户名，`plugin_name`是该插件github的项目名，通常就是插件的名字。
如果这里不写`git_name`，vundle默认在[vim-scripts](https://github.com/vim-scripts)用户中搜索插件。

然后进入Command Mode输入（按Esc键）

```vim
:PluginInstall
```
vundle会自动下载安装之前写在`~/.vimrc`中的插件。

## 文件树形结构插件：NERDTree
NERDTree可以让Vim想大多数IDLE一样在窗口一侧显示文件树形结构。Vim中使用窗口分割的方式实现的。分割窗口的切换可以通过`<Ctrl-ww>`完成。
项目主页: <https://github.com/scrooloose/nerdtree>

### 安装插件
- 在`~/.vimrc`的`vundle`段中添加

```vim
Plugin 'scrooloose/nerdtree'
```
- 在command mode下输入

```vim
:PluginInstall
```

### 配置NERDTree
在`~/.vimrc`中添加语句可以配置NERDTree。这些语句请根据个人喜好选择性添加

```vim
" 打开NERDTree快捷键，设置为<F2>
map <F2> :NERDTreeToggle<CR>

" 显示行号
let NERDTreeShowLineNumbers=1
let NERDTreeAutoCenter=1
" 是否显示隐藏文件
let NERDTreeShowHidden=1
" 设置宽度
let NERDTreeWinSize=30
" 在终端启动vim时，共享NERDTree
let g:nerdtree_tabs_open_on_console_startup=1
" 忽略以下文件的显示
let NERDTreeIgnore=['\.pyc','\~$','\.swp']
" 显示书签列表
let NERDTreeShowBookmarks=1

" 当vim中没有其他文件，值剩下nerdtree的时候，自动关闭窗口
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
```
### 使用NERDTree
将窗口切换至NERDTree，可以通过快捷键对文件树进行操作。

|   命令  |  功能  |
|--------|:-------:|
|o |打开关闭文件或者目录
|t |在标签页中打开
|T |在后台标签页中打开
|! |执行此文件
|p |到上层目录
|P |到根目录
|K |到第一个节点
|J |到最后一个节点
|u |打开上层目录
|m |显示文件系统菜单（添加、删除、移动操作）
|? |帮助
|q |关闭

## 自动注释与段注释插件：NerdCommenter
这是一个对代码进行快速注释的插件。在很多图形化IDE中`<Ctrl-/>`经常用来表示对光标所在行或选中行的注释。NerdCommenter可以帮助我们在vim中使用这些功能。\\
项目主页：https://github.com/scrooloose/nerdcommenter

### 安装插件
- 在`~/.vimrc`的`vundle`段中添加

```vim
Plugin 'scrooloose/nerdcommenter'
```
- 在command mode下输入

```vim
:PluginInstall
```

### 初次使用NerdCommenter
在没有任何配置的情况下插件已经可以使用了。具体说明可以查看`:help NERDCommenter`。最简单的注释/取消注释是通过`<Leader>c<Space>`实现的。

> vim的`<Leader>`键默认是`\`。

### 配置NerdCommenter
其实这个插件做的很不错了，几乎不需要太多的配置我只是根据个人习惯做了些小修改:
```
let g:NERDSpaceDelims = 1
imap <D-/> <Esc><leader>c<Space>a
imap <C-_> <Esc><leader>c<Space>a
map <C-_> <Leader>c<Space>
vmap <C-_> <Leader>c<Space>
```
- 第一行：在代码和注释间加一个空格。
- 第二行：应为我用的是Mac电脑所以对于单行注释空`<cmd-/>`代替。
- 第三～五行：用`<Ctrl-_>`进行单行或多行注释。

> - `<cmd-/>`只能进行单行注释的原因是这个快捷键有可能被图像窗口（MacVim或终端）的快捷键冲突。
- 这里不用`<Ctrl-/>`的原因是这个快捷键被Vim本身注册了。详见：[How to map `<C-/>` to toggle comments in vim?](https://stackoverflow.com/questions/9051837/how-to-map-c-to-toggle-comments-in-vim)
