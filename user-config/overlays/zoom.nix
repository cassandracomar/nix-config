self: super: {
  zoom-us = super.zoom-us.overrideAttrs (old: rec {
    qtWrapperArgs =
      [ "--prefix LD_PRELOAD : ${self.libv4l}/lib/libv4l/v4l2convert.so" ]
      ++ old.qtWrapperArgs;
  });
}
