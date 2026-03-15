//
//  WordDatabase.swift
//  SpellGuard
//
//  Seed word database for spelling bee practice
//

import Foundation
import SwiftData

// MARK: - Word Database Service
@MainActor
final class WordDatabase {
    static let shared = WordDatabase()
    private init() {}

    // MARK: - Seed Data
    func seedWordsIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Word>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let seedWords = Self.allSeedWords()
        for word in seedWords {
            modelContext.insert(word)
        }

        try? modelContext.save()
    }

    static func allSeedWords() -> [Word] {
        var words: [Word] = []
        words.append(contentsOf: kindergartenWords())
        words.append(contentsOf: grade1Words())
        words.append(contentsOf: grade2Words())
        words.append(contentsOf: grade3Words())
        words.append(contentsOf: grade4Words())
        words.append(contentsOf: grade5Words())
        words.append(contentsOf: satWords())
        return words
    }

    // MARK: - Kindergarten Words
    static func kindergartenWords() -> [Word] {
        let data: [(String, String, String)] = [
            ("cat", "A small domesticated carnivorous mammal.", "The cat sat on the mat."),
            ("dog", "A domesticated carnivorous mammal.", "My dog loves to play fetch."),
            ("run", "Move at a speed faster than a walk.", "I like to run in the park."),
            ("sun", "The star at the center of the solar system.", "The sun is bright today."),
            ("hat", "A shaped covering for the head.", "She wore a red hat."),
            ("big", "Of considerable size or extent.", "That is a big elephant."),
            ("bed", "A piece of furniture for sleeping.", "I sleep in my bed."),
            ("cup", "A small open container for drinking.", "Fill the cup with water."),
            ("fan", "A device for creating airflow.", "Turn on the fan, it's hot."),
            ("jam", "A sweet spread made from fruit.", "I like strawberry jam."),
            ("map", "A diagrammatic representation of an area.", "We used a map to find the park."),
            ("nap", "A short sleep.", "The baby took a nap."),
            ("pan", "A flat-bottomed metal container.", "Cook the eggs in a pan."),
            ("sap", "The juice of a plant.", "Maple sap makes syrup."),
            ("tap", "A light knock or touch.", "Give the door a tap."),
            ("van", "A medium-sized motor vehicle.", "We rode in the van."),
            ("wax", "A sticky yellowish substance.", "The candle is made of wax."),
            ("yam", "A starchy tuberous root vegetable.", "We ate yam for dinner."),
            ("zip", "Fasten with a zipper.", "Zip up your jacket."),
            ("box", "A container with flat sides.", "Put the toys in the box.")
        ]
        return data.map { Word(text: $0.0, definition: $0.1, exampleSentence: $0.2, gradeLevel: GradeLevel.kindergarten.rawValue, difficulty: 1) }
    }

    // MARK: - Grade 1 Words
    static func grade1Words() -> [Word] {
        let data: [(String, String, String)] = [
            ("apple", "A round fruit with red or green skin.", "I eat an apple every day."),
            ("bird", "A warm-blooded vertebrate animal with feathers.", "The bird sang a beautiful song."),
            ("cloud", "A visible mass of condensed water vapor.", "A big cloud covered the sun."),
            ("dress", "A one-piece garment worn by women.", "She wore a blue dress."),
            ("elephant", "The largest living land animal.", "The elephant has a long trunk."),
            ("flower", "The seed-bearing part of a plant.", "This flower smells wonderful."),
            ("green", "Of a color between blue and yellow.", "The grass is green."),
            ("happy", "Feeling or showing pleasure.", "I feel happy today."),
            ("insect", "A small invertebrate animal.", "A bee is an insect."),
            ("jump", "Push oneself off a surface into the air.", "Can you jump over the puddle?"),
            ("kite", "A toy flown in the wind on a string.", "We flew a kite at the beach."),
            ("lunch", "A meal eaten in the middle of the day.", "I had a sandwich for lunch."),
            ("mango", "A fleshy tropical fruit.", "The mango was sweet and juicy."),
            ("night", "The period from sunset to sunrise.", "Stars come out at night."),
            ("orange", "A round citrus fruit.", "I drank orange juice."),
            ("pencil", "A thin writing instrument.", "Use a pencil to draw."),
            ("quiet", "Making little or no noise.", "Be quiet in the library."),
            ("rabbit", "A small burrowing mammal.", "The rabbit hopped away."),
            ("smile", "Form one's features into a pleased expression.", "She gave a warm smile."),
            ("table", "A piece of furniture with a flat top.", "Put your book on the table.")
        ]
        return data.map { Word(text: $0.0, definition: $0.1, exampleSentence: $0.2, gradeLevel: GradeLevel.grade1.rawValue, difficulty: 1) }
    }

    // MARK: - Grade 2 Words
    static func grade2Words() -> [Word] {
        let data: [(String, String, String)] = [
            ("above", "At a higher level or position.", "The bird flew above the clouds."),
            ("begin", "Start or cause to start.", "Let's begin the lesson."),
            ("carry", "Hold and move someone or something.", "Can you carry this bag?"),
            ("dance", "Move rhythmically to music.", "She loves to dance."),
            ("early", "Before the usual time.", "We arrived early."),
            ("faint", "Barely perceptible.", "I heard a faint sound."),
            ("giant", "An imaginary being of great stature.", "The giant lived in a castle."),
            ("heart", "A hollow muscular organ that pumps blood.", "Your heart beats every second."),
            ("invent", "Create or design something new.", "Who did invent the telephone?"),
            ("jungle", "A tropical area with dense vegetation.", "Tigers live in the jungle."),
            ("kitchen", "A room for cooking.", "Mom cooks in the kitchen."),
            ("listen", "Give attention to sound.", "Listen to the music."),
            ("middle", "At an equal distance from extremes.", "Stand in the middle."),
            ("nature", "The phenomena of the physical world.", "I love spending time in nature."),
            ("outside", "Beyond the boundaries of a place.", "Let's play outside."),
            ("people", "Human beings in general.", "Many people came to the fair."),
            ("quarter", "One of four equal parts.", "Cut the apple into quarters."),
            ("reason", "A cause or explanation.", "What is the reason for this?"),
            ("silver", "A lustrous gray-white precious metal.", "The ring was made of silver."),
            ("travel", "Make a journey.", "We love to travel."),
        ]
        return data.map { Word(text: $0.0, definition: $0.1, exampleSentence: $0.2, gradeLevel: GradeLevel.grade2.rawValue, difficulty: 2) }
    }

    // MARK: - Grade 3 Words
    static func grade3Words() -> [Word] {
        let data: [(String, String, String)] = [
            ("ancient", "Belonging to the very distant past.", "The ancient ruins were fascinating."),
            ("balance", "An even distribution of weight.", "She lost her balance on the ice."),
            ("capture", "Take into one's possession.", "The explorer tried to capture the butterfly."),
            ("declare", "Make a formal announcement.", "The mayor will declare a holiday."),
            ("elegant", "Pleasingly graceful and stylish.", "She wore an elegant gown."),
            ("fascinate", "Draw irresistibly the attention of.", "Dinosaurs fascinate children."),
            ("generous", "Showing a readiness to give.", "The generous donor helped many families."),
            ("harvest", "Gather a ripe crop.", "The farmers harvested the wheat."),
            ("imagine", "Form a mental image of something.", "Imagine a world without pollution."),
            ("journey", "An act of traveling from one place to another.", "The journey took three hours."),
            ("knowledge", "Facts or information acquired.", "Knowledge is power."),
            ("leisure", "Time when one is not working.", "He enjoys reading in his leisure time."),
            ("mystery", "Something not fully understood.", "The disappearance remains a mystery."),
            ("navigate", "Plan and direct the route.", "The captain navigated the ship."),
            ("obstacle", "A thing that blocks one's way.", "She overcame every obstacle."),
            ("patience", "The capacity to accept delay without anger.", "Patience is a virtue."),
            ("quality", "The standard of something.", "This product is of high quality."),
            ("rescue", "Save from a dangerous situation.", "The firefighter performed a daring rescue."),
            ("solution", "A means of solving a problem.", "What is the solution to this problem?"),
            ("triumph", "A great victory or achievement.", "The team celebrated their triumph.")
        ]
        return data.map { Word(text: $0.0, definition: $0.1, exampleSentence: $0.2, gradeLevel: GradeLevel.grade3.rawValue, difficulty: 2) }
    }

    // MARK: - Grade 4 Words
    static func grade4Words() -> [Word] {
        let data: [(String, String, String)] = [
            ("abolish", "Formally put an end to a system or practice.", "They voted to abolish the old rule."),
            ("abundant", "Present in great quantity.", "Fish are abundant in this lake."),
            ("cautious", "Careful to avoid potential problems.", "Be cautious when crossing the street."),
            ("defiant", "Showing resistance or bold disobedience.", "The defiant student refused to sit."),
            ("eloquent", "Fluent or persuasive in speaking.", "He gave an eloquent speech."),
            ("ferocious", "Savagely fierce.", "The ferocious lion roared."),
            ("grievance", "A real or imagined wrong.", "She filed a formal grievance."),
            ("habitual", "Done constantly as a habit.", "He is a habitual reader."),
            ("illuminate", "Light up or make clear.", "Candles illuminate the room."),
            ("jealous", "Feeling envy of someone.", "She was jealous of his success."),
            ("legitimate", "Conforming to the law.", "Is this a legitimate business?"),
            ("melancholy", "A feeling of deep sadness.", "The music filled her with melancholy."),
            ("notorious", "Famous for some bad quality.", "The notorious pirate sailed the seas."),
            ("ominous", "Giving the impression something bad will happen.", "The dark clouds looked ominous."),
            ("peculiar", "Strange or unusual.", "There was a peculiar smell in the room."),
            ("recipient", "A person who receives something.", "She was the recipient of the award."),
            ("sovereign", "A supreme ruler.", "The sovereign ruled the land with fairness."),
            ("temperate", "Moderate in behavior or climate.", "This region has a temperate climate."),
            ("unanimous", "Fully in agreement.", "The vote was unanimous."),
            ("vigilant", "Keeping careful watch.", "Be vigilant about your surroundings.")
        ]
        return data.map { Word(text: $0.0, definition: $0.1, exampleSentence: $0.2, gradeLevel: GradeLevel.grade4.rawValue, difficulty: 3) }
    }

    // MARK: - Grade 5 Words
    static func grade5Words() -> [Word] {
        let data: [(String, String, String)] = [
            ("accommodate", "Provide lodging or space.", "The hotel can accommodate 500 guests."),
            ("benevolent", "Well meaning and kindly.", "The benevolent king cared for his people."),
            ("commemorate", "Recall and show respect for.", "A statue was built to commemorate the hero."),
            ("deteriorate", "Become progressively worse.", "Without care, the building will deteriorate."),
            ("exaggerate", "Represent as greater than it really is.", "Don't exaggerate the story."),
            ("fundamental", "Forming a necessary base.", "Trust is fundamental to any friendship."),
            ("guarantee", "A formal pledge to ensure outcome.", "They offer a money-back guarantee."),
            ("humanitarian", "Concerned with human welfare.", "She works for a humanitarian organization."),
            ("inevitable", "Certain to happen.", "Change is inevitable."),
            ("jurisdiction", "The authority to make legal decisions.", "This falls under federal jurisdiction."),
            ("legitimate", "Conforming to the law or to rules.", "He had a legitimate reason to be late."),
            ("meticulous", "Showing great attention to detail.", "She was meticulous in her research."),
            ("negligible", "So small as to be not worth considering.", "The difference was negligible."),
            ("opulent", "Ostentatiously rich and luxurious.", "They lived in an opulent mansion."),
            ("perpetual", "Never ending or changing.", "The mountain streams are in perpetual flow."),
            ("quarantine", "Isolate to prevent spread of disease.", "The sick animals were placed in quarantine."),
            ("resilient", "Able to withstand or recover quickly.", "Children are very resilient."),
            ("scrutinize", "Examine thoroughly.", "She scrutinized every word of the contract."),
            ("treacherous", "Guilty of betrayal.", "The treacherous path was full of ice."),
            ("unprecedented", "Never done or known before.", "It was an unprecedented achievement.")
        ]
        return data.map { Word(text: $0.0, definition: $0.1, exampleSentence: $0.2, gradeLevel: GradeLevel.grade5.rawValue, difficulty: 3) }
    }

    // MARK: - SAT Words
    static func satWords() -> [Word] {
        let data: [(String, String, String, String)] = [
            ("aberrant", "Departing from an accepted standard.", "His aberrant behavior shocked everyone.", "adjective"),
            ("acrimony", "Bitterness or ill feeling.", "The divorce was full of acrimony.", "noun"),
            ("alacrity", "Brisk and cheerful readiness.", "She accepted the task with alacrity.", "noun"),
            ("ambivalent", "Having mixed feelings.", "She felt ambivalent about the decision.", "adjective"),
            ("ameliorate", "Make something bad better.", "Efforts to ameliorate poverty continue.", "verb"),
            ("anachronism", "Something out of its time.", "A knight with a cellphone is an anachronism.", "noun"),
            ("antipathy", "A deep-seated feeling of dislike.", "She felt antipathy toward dishonesty.", "noun"),
            ("apocryphal", "Of doubtful authenticity.", "The story is likely apocryphal.", "adjective"),
            ("arcane", "Understood by only a few.", "The professor used arcane terminology.", "adjective"),
            ("arduous", "Involving a lot of effort.", "It was an arduous climb to the summit.", "adjective"),
            ("belligerent", "Hostile and aggressive.", "The belligerent crowd alarmed the police.", "adjective"),
            ("bombastic", "High-sounding but with little meaning.", "His speech was bombastic and hollow.", "adjective"),
            ("cacophony", "A harsh mixture of sounds.", "The city streets are full of cacophony.", "noun"),
            ("capricious", "Given to sudden changes of mood.", "The weather here is quite capricious.", "adjective"),
            ("chicanery", "The use of trickery to achieve goals.", "The lawyer accused him of chicanery.", "noun"),
            ("circumspect", "Wary and unwilling to take risks.", "She was circumspect in her investments.", "adjective"),
            ("clandestine", "Kept secret or done secretively.", "They held clandestine meetings at night.", "adjective"),
            ("cogent", "Clear, logical, and convincing.", "She made a cogent argument.", "adjective"),
            ("complacent", "Showing uncritical satisfaction with oneself.", "Don't become complacent after success.", "adjective"),
            ("contentious", "Causing or likely to cause disagreement.", "Immigration is a contentious issue.", "adjective"),
            ("deleterious", "Causing harm or damage.", "Smoking has deleterious effects on health.", "adjective"),
            ("demagogue", "A leader who appeals to popular desires.", "The demagogue stirred up the crowd.", "noun"),
            ("deprecated", "Express disapproval of.", "The practice is now deprecated.", "verb"),
            ("didactic", "Intended to teach.", "The story had a didactic purpose.", "adjective"),
            ("dilettante", "A person with a superficial interest.", "He was a dilettante, not a real scholar.", "noun"),
            ("dissonance", "Lack of harmony or inconsistency.", "There was cognitive dissonance in his beliefs.", "noun"),
            ("ebullient", "Cheerful and full of energy.", "She was ebullient after the victory.", "adjective"),
            ("efficacious", "Successful in producing a desired result.", "The medicine was efficacious.", "adjective"),
            ("egregious", "Outstandingly bad.", "It was an egregious error.", "adjective"),
            ("equivocate", "Use ambiguous language to conceal truth.", "Politicians often equivocate on hard issues.", "verb")
        ]
        return data.map { Word(text: $0.0, definition: $0.1, exampleSentence: $0.2, gradeLevel: GradeLevel.sat.rawValue, partOfSpeech: $0.3, difficulty: 5) }
    }
}
