import sdlang;

enum RecipeOS {
	Universal = 0x0,
	Linux = 0x01,
	FreeBSD = 0x02,
	MacOSX = 0x04,
	Win32 = 0x08
}

class ContentDefinition {
	public string Author;
	public string License;
	public string Message;
	public string[string] Attributes;

	this() {

	}

	this(Tag t) {
		Tag author_tag = t.tags["author"][0];
		this.Author = author_tag.values[0].get!(string);

		Tag license_tag = t.tags["license"][0];
		this.License = license_tag.values[0].get!(string);
		
		Tag message_tag = t.tags["message"][0];
		this.Message = message_tag.values[0].get!(string);		
	}
}

class ContentRecipeDefinition : ContentDefinition {
	RecipeOS HostOS;
}

class ContentFileDefinition : ContentDefinition  {
	public string Origin;

	this(Tag root) {
		super(root);
		
		Tag origin_tag = root.tags["origin"][0];
		this.Origin = origin_tag.values[0].get!(string);

		foreach(Tag recipe; root.tags["recipe"]) {
			
		}
	}
	ContentRecipeDefinition[] Recipes;
}

