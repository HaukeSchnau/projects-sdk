# What the shop needs from a host, in its repository. docs/project-definition.md has every field.
{
  project = {
    name = "shop";
    parameters.title = {
      description = "The site's title";
      default = "Shop";
    };
    release = {
      backend = "static";
      health.paths = [ "/" ];
    };
  };
}
