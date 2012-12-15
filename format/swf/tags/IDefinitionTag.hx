package format.swf.tags;

interface IDefinitionTag implements ITag
{
	var characterId:Int;
	
	function clone():IDefinitionTag;
}