# vim-stupidcomplete
A small indent-based usercomplete function for vim. It's supposed to replace
the default all-word completion, but be aware of the indentaion of the words
it looks up.

## Principle
This completion is not aware of your language, it will suggest you all the
words it will find. But it only looks for words in correctly indented lines.
In the following example;
`1   aaa`
`2      bbb`
`3         ccc`
`4      ddd` <-- cursor on this line
`5         eee`
`6   fff`
`7      ggg`
it will suggest you words aaa, bbb and fff, but not ccc or eee or ggg.

## Installation
Use your favourite plugin manager, or just dump the plugin into your .vim
folder.

For Pathogen:
`cd ~/.vim/bundle && git clone https://github.com/d86leader/vim-stupidcomplete`

For vim-plug and similar, add the following line to your vimrc file after
initializing the manager:
`Plug 'd86leader/vim-stupidcomplete'`

## Usage
As this completion is intended to replace the default all-word completion, you
want to make it your usercomplete function:
`set completefunction=Stupidcomplete`
And then you want to make the following remappings:
`inoremap <expr> <C-N> pumvisible() ? "\<C-N>":"\<C-X>\<C-U>"`
`inoremap <expr> <C-P> pumvisible() ? "\<C-P>":"\<C-X>\<C-U>\<C-P>\<C-P>"`
This will allow you to start stupidcompletion by pressing Ctrl-n and Ctrl-p
