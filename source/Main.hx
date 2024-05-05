import haxe.Json;
import SMParser.Timings;
import sys.io.File;
import sys.FileSystem;

using StringTools;

typedef FNFSection = {
	sectionNotes:Array<Array<Dynamic>>,
	lengthInSteps:Int,
	typeOfSection:Int,
	mustHitSection:Bool,
	bpm:Int,
	changeBPM:Bool,
	altAnim:Bool
}

typedef FNFChart = {
    song:String,
    notes:Array<FNFSection>,
    bpm: Float,
    needsVoices: Bool,
    speed:Float, 
	player1:String,
	player2:String
}

class Main extends mcli.CommandLine {
	public function runDefault(?smPath:String, ?difficulty:String, adjust:String='y') {
		if (smPath == null){
            Sys.println("Define a path!");
            return;
        }
		if (difficulty == null) {
			Sys.println("Define a difficulty!");
			return;
		}
        var adjustingOffset:Bool = true;
		if (adjust == 'f' || adjust == 'false' || adjust=='no')
            adjustingOffset = false;
        
		if (FileSystem.exists(smPath)){
            var content = File.getContent(smPath);
			Sys.println("Reading that shit!!");
			var smData = SMParser.readSM(content, adjustingOffset);
            if(!smData.notes.exists(difficulty)){
                Sys.println(difficulty + " is not a valid difficulty!");
                var diffs:Array<String> = [];
                for(shit in smData.notes.keys())diffs.push(shit);
				Sys.println("Valid difficulties are " + diffs.join(", "));
                return;
            }
            Sys.println("Converting " + smData.metadata.get("TITLE") + " (" + difficulty + ")");
            var theChart:FNFChart = {
				song: smData.metadata.get("TITLE").toLowerCase().replace(" ", "-"),
				notes: [],
				bpm: smData.bpmChanges[0].bpm,
				needsVoices: false,
				speed: 3.0,
				player1: "bf",
				player2: "dad"
            }

            var timings = new Timings(smData.bpmChanges);
			var lastSex:Int = 0;
			var type = smData.notes.get(difficulty).type;
            var lastBPMChangeBeat = timings.getTiming(0).beat;
            for(note in smData.notes.get(difficulty).notes){
                var beat = note.beat;
                
                var section:Int = Math.floor(beat / 4);
                for (i in lastSex...section + 1){
                    var sectionBeat = i * 4;
					var timing = timings.getTimingAtBeat(sectionBeat);
                    if (theChart.notes[i] == null){
                        theChart.notes[i] = {
                            sectionNotes: [],
                            lengthInSteps: 16,
                            typeOfSection: 0,
							mustHitSection: (type == 'dance-single'),
							bpm: Std.int(timing.bpm),
							changeBPM: timing.beat > lastBPMChangeBeat,
                            altAnim: false
                        }
						lastBPMChangeBeat = timing.beat;
                    }
                }
                
                lastSex = section + 1;
                
                
				theChart.notes[section].sectionNotes.push([note.time, note.column, note.length]);
            }

            File.saveContent(theChart.song + ".json", Json.stringify({
                "song": theChart
            }, "\t"));
			Sys.println("Converted! " + theChart.song + ".json");

        }else{
            Sys.println(smPath + " doesn't exist!");
        }
	}

	static public function main():Void new mcli.Dispatch(Sys.args()).dispatch(new Main());
	
}