## 问题

### VapourSynth 破坏性更新

> Tue May 5 09:08:30 CEST 2026

- `extra/vapoursynth` 包更新至 75 版本后 (此问题其实是 R74 引入的, 但他们似乎跳过了 R74 直接在近几天更新至 R75), vsscript 库文件符号链接关系如下:
  - `/usr/lib/libvapoursynth-script.so` -> `python3.14/site-packages/vapoursynth/libvsscript.so`
  - `/usr/lib/libvapoursynth-script.so.0` -> `python3.14/site-packages/vapoursynth/libvsscript.so`

  这导致 ldconfig 根据 SONAME 字段建立的缓存条目变化, 例如从 `libvapoursynth-script.so.0 (libc,x86-64) => /usr/lib/libvapoursynth-script.so.0` 变为 `libvsscript.so (libc6,x86-64) => /usr/lib/libvsscript.so`, 可能会使其他未能重新链接的程序找不到对应库.

  但该问题影响范围比较有限, 因为动态库并不完全根据 ldconfig 缓存条目加载 —— 如果文件名完全匹配也能正确加载, 毕竟 `/usr/lib/libvapoursynth-script.so.0` 仍然存在.

- 同时, 插件目录也从 `/usr/lib/vapoursynth/` 改为 `/usr/lib/python3.14/site-packages/vapoursynth/plugins/`, 很多包未能及时更新插件安装路径, 导致 vapoursynth 插件丢失.

  extra 仓库中的 vapoursynth-plugin-\* 包均已改为类似如下动态查找插件安装路径的方式:

  ```bash
  install -Dm 755 libxxx.so -t "${pkgdir}"/$(python -c 'import vapoursynth;print(vapoursynth.get_plugin_dir())')/
  ```

  所以不会出问题. 主要影响范围是打包者或上游硬编码插件安装路径为 `/usr/lib/vapoursynth` 的包, 其中包括少数 extra 仓库的包如 `extra/ffms2` 和众多 AUR 包.

  临时修复方法:

  ```bash
  old_dir="/usr/lib/vapoursynth"
  new_dir="$(python -c 'import vapoursynth;print(vapoursynth.get_plugin_dir())')"
  if [ "$(realpath "$old_dir" 2>/dev/null)" != "$(realpath "$new_dir")" ] && [ -d "$old_dir" ]; then
    for f in "$old_dir"/*.so; do
      if [ -L "$f" ]; then p="$(readlink -m "$f")"; elif [ -f "$f" ]; then p="$f"; else continue; fi
      ln -svr "$p" "$new_dir/$(basename "$f")"
    done
  fi
  unset old_dir new_dir f p
  ```

- vapoursynth 不再在编译期链接 libpython, 而必须在加载 libvsscript.so 时选择 python. 选哪个 python 由 `$HOME/.config/vapoursynth/vapoursynth.toml` 维护的映射关系决定, 格式类似:

  ```toml
  "/usr/lib/python3.14/site-packages/vapoursynth/libvsscript.so" = ["/usr/bin/python","/usr/lib/libpython3.14.so.1.0"]
  ```

  可以运行 `vapoursynth config` 自动更新.

  然而, 上文提到过新的 libvsscript.so 的 ldconfig 条目是 `libvsscript.so (libc6,x86-64) => /usr/lib/libvsscript.so`, 而 `vapoursynth config` 只会在 `vapoursynth.toml` 写入 `/usr/lib/python3.14/site-packages/vapoursynth/libvsscript.so` 的条目. 此时, 如果加载 libvsscript.so, 会从 ldconfig 拿到 `/usr/lib/libvsscript.so`，而 vapoursynth 在拿到此路径后不解 symlink, 查 `vapoursynth.toml` 时和任何条目都对不上, 导致加载失败. 报错类似:

  ```
  Python executable and library path couldn't be determined despite automatic configuration. Run `vapoursynth config` to set it for this Python installation and then try again.
  ```

  临时修复方式为在 `$HOME/.config/vapoursynth/vapoursynth.toml` 里手动加上针对 `/usr/lib/libvsscript.so` 符号链接的条目:

  ```toml
  "/usr/lib/libvsscript.so" = ["/usr/bin/python","/usr/lib/libpython3.14.so.1.0"]
  ```

  如果运行 vapoursynth 此次更新前构建并链接的程序, 可能同样需要为 `/usr/lib/libvapoursynth-script.so.0` 准备对应条目:

  ```toml
  "/usr/lib/libvapoursynth-script.so.0" = ["/usr/bin/python","/usr/lib/libpython3.14.so.1.0"]
  ```

  影响范围为所有动态链接 vapoursynth 的二进制文件.

### CUDA 13.2 不兼容 GCC 16.1

> Mon May 4 15:39:17 CEST 2026

nvcc 和 gcc 兼容问题的历史重演. 随 GCC 16.1 发布, 以前用 GCC 15.2 能够编译的 CUDA 包会报一堆错误, 影响范围非常大.

解决方法为装 gcc15 等旧版本工具链, 并修改编译流程使 nvcc 使用指定编译器. 例如对于部分 Makefile:

```makefile
CUDA_CCBIN ?=
cudaccbin = $(if $(CUDA_CCBIN),-ccbin $(CUDA_CCBIN),)

...

nvcc $(cudaccbin) ...
```

但这样会带来一个问题: `gcc15` 是 AUR 包, 需要编译. 而这并不会是一个很愉快的过程. 除去超大的仓库体积, 超长时间的编译测试和超高的资源占用外, 过程中还可能会因为各种问题失败, 修复问题后可能还需要从头再来, 成本过高.

但好在 cachyos 有打包 `gcc14` 二进制包, 因此再降一个版本即可绕过编译过程. 但 AUR 上的众多打包者应该还是会选择 `gcc15`, 因此在有仓库打包 `gcc15` 二进制包或 NVIDIA 更新 CUDA 支持 GCC 16 之前, 几乎所有涉及 CUDA 的包仍然需要手动修改 PKGBUILD 构建.

另外还有几个可选方案:

- 可以用 clang++ 代替 nvcc, 但支持程度似乎有限 (`clang++: warning: CUDA version is newer than the latest partially supported version 12.9 [-Wunknown-cuda-version]`), 且对于部分已经在使用 nvcc 构建的项目可能需要较大幅度地修改编译参数和流程, 实用价值不高.
