pub usingnamespace @cImport({
    @cDefine("_GNU_SOURCE", {});
    @cInclude("stdio.h");

    @cDefine("HAVE_CONFIG_H", {});
    @cInclude("setshow.h");
    @cInclude("fit.h");
    @cInclude("gadgets.h");
    @cInclude("voxelgrid.h");
    @cInclude("term_api.h");
    @cInclude("misc.h");
    @cInclude("command.h");
});
