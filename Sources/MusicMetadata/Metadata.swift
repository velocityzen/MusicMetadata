import Foundation
import FileType

public struct Metadata {
  var type: FileTypeExtension?
  var mime: String?
  var ext: String?

  var title: String?                 //Track title
  var artist: String?                //Track, maybe several artists written in a single string.
  var artists: [String]?             //Track artists, aims to capture every artist in a different string.
  var albumartist: String?           //Track album artists
  var album: String?                 //Album title
  var year: Int?                     //Release year
  var originalyear: Int?             //Original release year
  var date: String?                  //Release date
  var originaldate: String?          //Original release date
  var comment: [String]?             //List of comments
  var genre: [String]?               //Genre

  var track: Int?
  var totaltracks: Int?
  var disk: Int?
  var totaldiscs: Int?

  var lyrics: [String]?              // Lyrics
  var lyricist: [String]?            // Lyricist(s)

  var albumsort: String?             // Album title, formatted for alphabetic ordering
  var titlesort: String?             // Track title, formatted for alphabetic ordering
  var artistsort: String?            // Track artist, formatted for alphabetic ordering
  var albumartistsort: String?       // Album artist, formatted for alphabetic ordering
  var composersort: [String]?        // Composer(s), formatted for alphabetic ordering

  var composer: [String]?            // Track composer
  var work: String?                  // The canonical title of the work
  var writer: [String]?              // Writer(s)
  var conductor: [String]?           // Conductor(s)
  var remixer: [String]?             // Remixer(s)
  var arranger: [String]?            // Arranger(s)
  var engineer: [String]?            // Engineer(s)
  var producer: [String]?            // Producer(s)
  var djmixer: [String]?             // Mix-DJ(s)
  var mixer: [String]?               // Mixed by
  var technician: [String]?
  var label: [String]?
  var grouping: [String]?
  var subtitle: [String]?
  var discsubtitle: [String]?
  var compilation: String?
  var bpm: Float?
  var key: String?                   //The initial key of the music in the file, e.g. "A Minor".
  var mood: String?                  // Keywords to reflect the mood of the audio, e.g. 'Romantic' or 'Sad'
  var media: String?                 // Release format, e.g. 'CD'
  var catalognumber: [String]?       // Release catalog number(s)

  var tvShow: String?                // TV show title
  var tvShowSort: String?            // TV show title, formatted for alphabetic ordering
  var tvSeason: Int?                 // TV season title sequence number
  var tvEpisode: Int?                // TV Episode sequence number
  var tvEpisodeId: String?           // TV episode ID
  var tvNetwork: String?             // TV network

  var podcast: String?
  var podcasturl: String?
  var releasestatus: String?
  var releasetype: [String]?
  var releasecountry: String?
  var script: String?
  var language: String?
  var copyright: String?
  var license: String?
  var encodedby: String?
  var encodersettings: String?
  var gapless: Bool?
  var barcode: String?

  var isrc: [String]?                // International Standard Recording Code
  var asin: String?

  var website: String?
  var performerInstrument: [String]?
  var averageLevel: Double?
  var peakLevel: Double?
  var notes: [String]?
  var originalalbum: String?
  var originalartist: String?

  public struct Picture {
    let format: String              //Image mime type
    let data: Data                  //Image data
    var description: String?
    var type: String?
    var name: String?
  }
  var pictures: [Picture]?          //Embedded album art

  public struct Rating {
    var source: String?             //Rating source, could be an e-mail address
    var rating: Float               //Rating [0..1]
  }
  var rating: [Rating]?

  public struct MusicBrainz {
    var recordingid: String?
    var trackid: String?
    var albumid: String?
    var originalalbumid: String?
    var artistid: [String]?
    var originalartistid: String?
    var albumartistid: [String]?
    var releasegroupid: String?
    var workid: String?
    var trmid: String?
    var discid: String?
  }
  var musicbrainz: MusicBrainz?

  public struct Discogs {
    var artist_id: [Int]?
    var release_id: Int?
    var label_id: Int?
    var master_release_id: Int?
    var votes: Int?
    var rating: Int?
  }
  var discogs: Discogs?

  public struct ReplayGain {
    public struct Ratio {
      var ratio: Float;                 //[0..1]
      var dB: Double;                   // Decibel
    }

    var trackGainRatio: Double?         //Track gain ratio [0..1]
    var trackPeakRatio: Double?         //Track peak ratio [0..1]
    var trackGain: Ratio?               //Track gain ratio
    var trackPeak: Ratio?               //Track peak ratio
    var trackRange: Ratio?              //Track peak ratio

    var albumGain: Ratio?               //Album gain ratio
    var albumPeak: Ratio?               //Album peak ratio
    var albumRange: Ratio?              //Album peak ratio

    var trackMinMax: [Double]?          //minimum & maximum global gain values across a set of files scanned as an album
  }
  var replayGain: ReplayGain?

  public struct AcoustId {
    var id: String?
    var fingerprint: String?
  }
  var acoustid: AcoustId?

  public struct MusicIp {
    var puid: String?
    var fingerprint: String?
  }
  var musicip: MusicIp?

}
