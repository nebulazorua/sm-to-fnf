import haxe.Json;
import SMParser.Timings;
import sys.io.File;
import sys.FileSystem;

using StringTools;



class Main extends mcli.CommandLine {
	
    public var nuFNF:Bool = false;

	public function runDefault(?smPath:String, ?difficulty:String, adjust:String='y') {
		if (smPath == null){
            Sys.println("Define a path!");
            return;
        }

        var adjustingOffset:Bool = true;
		if (adjust == 'f' || adjust == 'false' || adjust=='no')
            adjustingOffset = false;

        if(nuFNF)
            adjustingOffset = false; // V-Slice has its own Offset field
        
		if (FileSystem.exists(smPath)){
            var content = File.getContent(smPath);
			Sys.println("Reading that shit!!");
			var smData = SMParser.readSM(content, adjustingOffset);
            if(!nuFNF){
                if (difficulty == null) {
                    difficulty = smData.difficulties[0];
                    Sys.println("No difficulty defined!! Defaulting to " + difficulty);
                }

                if(!smData.notes.exists(difficulty)){
                    Sys.println(difficulty + " is not a valid difficulty!");
                    var diffs:Array<String> = [];
                    for(shit in smData.notes.keys())diffs.push(shit);
                    Sys.println("Valid difficulties are " + diffs.join(", "));
                    return;
                }
                Sys.println("Converting " + smData.metadata.get("TITLE") + " (" + difficulty + ")");
                var converted = SMToLegacy.convert(smData, difficulty);
                File.saveContent(converted.song.song + ".json", Json.stringify(converted, "\t"));
                Sys.println("Converted! " + converted.song.song + ".json");
            }else{
				Sys.println("Converting " + smData.metadata.get("TITLE"));
				var converted = SMToFNF.convert(smData, difficulty);
                var name = smData.metadata.get("TITLE").toLowerCase().replace(" ","-");
				File.saveContent(name + "-metadata.json", Json.stringify(converted.metadata, "\t"));
				File.saveContent(name + "-chart.json", Json.stringify(converted.chart, "\t"));
				Sys.println("Converted! " + name + "-metadata.json + " + name + "-chart.json");
            }

        }else{
            Sys.println(smPath + " doesn't exist!");
        }
	}

	static public function main():Void new mcli.Dispatch(Sys.args()).dispatch(new Main());
	
}