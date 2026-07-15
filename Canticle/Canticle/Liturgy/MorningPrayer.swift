import Foundation

/// The fixed text of the 1662 Order for Daily Morning Prayer, with the day-specific Psalms,
/// Lessons, and Collect of the Day represented as slots that `DevotionalViewModel` fills at
/// runtime from `CalendarStore`.
///
/// NOTE: transcribed from the 1662 Book of Common Prayer from memory for this scaffold. Proofread
/// against an authoritative edition (e.g. the Cambridge "Standard Book") before shipping.
enum MorningPrayer {
    static let items: [LiturgyItem] = [
        .heading(Office.morning.title),

        .rubric("The Minister shall read one or more of these Sentences of Scripture."),
        .sentence("The Lord is in his holy temple: let all the earth keep silence before him. — Habakkuk 2:20"),
        .sentence("I will arise, and go to my father, and will say unto him, Father, I have sinned against heaven, and before thee. — Luke 15:18,19"),
        .sentence("Enter not into judgement with thy servant, O Lord; for in thy sight shall no man living be justified. — Psalm 143:2"),

        .heading("The Exhortation"),
        .text("Dearly beloved brethren, the Scripture moveth us in sundry places to acknowledge and confess our manifold sins and wickedness; and that we should not dissemble nor cloke them before the face of Almighty God our heavenly Father; but confess them with an humble, lowly, penitent, and obedient heart; to the end that we may obtain forgiveness of the same, by his infinite goodness and mercy. And although we ought at all times humbly to acknowledge our sins before God; yet ought we most chiefly so to do, when we assemble and meet together to render thanks for the great benefits that we have received at his hands, to set forth his most worthy praise, to hear his most holy Word, and to ask those things which are requisite and necessary, as well for the body as the soul. Wherefore I pray and beseech you, as many as are here present, to accompany me with a pure heart and humble voice unto the throne of the heavenly grace, saying after me:"),

        .rubric("A general Confession to be said of the whole Congregation, kneeling."),
        .text("Almighty and most merciful Father; We have erred and strayed from thy ways like lost sheep. We have followed too much the devices and desires of our own hearts. We have offended against thy holy laws. We have left undone those things which we ought to have done; And we have done those things which we ought not to have done; And there is no health in us. But thou, O Lord, have mercy upon us, miserable offenders. Spare thou them, O God, which confess their faults. Restore thou them that are penitent; According to thy promises declared unto mankind in Christ Jesus our Lord. And grant, O most merciful Father, for his sake; That we may hereafter live a godly, righteous, and sober life, To the glory of thy holy Name. Amen."),

        .rubric("The Absolution, or Remission of sins, to be pronounced by the Priest alone, standing; the people still kneeling."),
        .text("Almighty God, the Father of our Lord Jesus Christ, who desireth not the death of a sinner, but rather that he may turn from his wickedness and live; and hath given power, and commandment, to his Ministers, to declare and pronounce to his people, being penitent, the Absolution and Remission of their sins: He pardoneth and absolveth all them that truly repent, and unfeignedly believe his holy Gospel. Wherefore let us beseech him to grant us true repentance, and his Holy Spirit, that those things may please him which we do at this present; and that the rest of our life hereafter may be pure and holy; so that at the last we may come to his eternal joy; through Jesus Christ our Lord."),
        .amen(),

        .rubric("The people shall answer here, and at the end of all other prayers, Amen. And the Minister shall kneel down, and say the Lord's Prayer, the people also kneeling, and repeating it with him."),
        .text("Our Father, which art in heaven, Hallowed be thy Name. Thy kingdom come. Thy will be done, in earth as it is in heaven. Give us this day our daily bread. And forgive us our trespasses, As we forgive them that trespass against us. And lead us not into temptation, But deliver us from evil. For thine is the kingdom, The power, and the glory, For ever and ever. Amen."),

        .versicle("O Lord, open thou our lips."),
        .response("And our mouth shall shew forth thy praise."),
        .versicle("O God, make speed to save us."),
        .response("O Lord, make haste to help us."),
        .text("Glory be to the Father, and to the Son, and to the Holy Ghost; As it was in the beginning, is now, and ever shall be, world without end. Amen."),
        .text("Praise ye the Lord."),
        .response("The Lord's Name be praised."),

        .canticleTitle("Venite, exultemus Domino. — Psalm 95"),
        .text("O come, let us sing unto the Lord: let us heartily rejoice in the strength of our salvation. Let us come before his presence with thanksgiving: and shew ourselves glad in him with psalms. For the Lord is a great God: and a great King above all gods. In his hand are all the corners of the earth: and the strength of the hills is his also. The sea is his, and he made it: and his hands prepared the dry land. O come, let us worship, and fall down: and kneel before the Lord our Maker. For he is the Lord our God: and we are the people of his pasture, and the sheep of his hand. To-day if ye will hear his voice, harden not your hearts: as in the provocation, and as in the day of temptation in the wilderness; When your fathers tempted me: proved me, and saw my works. Forty years long was I grieved with this generation, and said: It is a people that do err in their hearts, for they have not known my ways; Unto whom I sware in my wrath: that they should not enter into my rest."),
        .text("Glory be to the Father, and to the Son, and to the Holy Ghost; As it was in the beginning, is now, and ever shall be, world without end. Amen."),

        .rubric("Then shall follow the Psalms in order as they are appointed."),
        .psalmsSlot,
        .text("Glory be to the Father, and to the Son, and to the Holy Ghost; As it was in the beginning, is now, and ever shall be, world without end. Amen."),

        .rubric("Then shall be read the First Lesson."),
        .firstLessonSlot,

        .canticleTitle("Te Deum Laudamus"),
        .text("We praise thee, O God: we acknowledge thee to be the Lord. All the earth doth worship thee: the Father everlasting. To thee all Angels cry aloud: the Heavens, and all the Powers therein. To thee Cherubin, and Seraphin: continually do cry, Holy, Holy, Holy: Lord God of Sabaoth; Heaven and earth are full of the Majesty: of thy glory. The glorious company of the Apostles: praise thee. The goodly fellowship of the Prophets: praise thee. The noble army of Martyrs: praise thee. The holy Church throughout all the world: doth acknowledge thee; The Father: of an infinite Majesty; Thine honourable, true: and only Son; Also the Holy Ghost: the Comforter."),
        .text("Thou art the King of Glory: O Christ. Thou art the everlasting Son: of the Father. When thou tookest upon thee to deliver man: thou didst not abhor the Virgin's womb. When thou hadst overcome the sharpness of death: thou didst open the kingdom of heaven to all believers. Thou sittest at the right hand of God: in the glory of the Father. We believe that thou shalt come: to be our Judge. We therefore pray thee, help thy servants: whom thou hast redeemed with thy precious blood. Make them to be numbered with thy Saints: in glory everlasting."),
        .text("O Lord, save thy people: and bless thine heritage. Govern them: and lift them up for ever. Day by day: we magnify thee; And we worship thy Name: ever world without end. Vouchsafe, O Lord: to keep us this day without sin. O Lord, have mercy upon us: have mercy upon us. O Lord, let thy mercy lighten upon us: as our trust is in thee. O Lord, in thee have I trusted: let me never be confounded."),

        .rubric("Then shall be read the Second Lesson."),
        .secondLessonSlot,

        .canticleTitle("Jubilate Deo. — Psalm 100"),
        .text("O be joyful in the Lord, all ye lands: serve the Lord with gladness, and come before his presence with a song. Be ye sure that the Lord he is God: it is he that hath made us, and not we ourselves; we are his people, and the sheep of his pasture. O go your way into his gates with thanksgiving, and into his courts with praise: be thankful unto him, and speak good of his Name. For the Lord is gracious, his mercy is everlasting: and his truth endureth from generation to generation."),
        .text("Glory be to the Father, and to the Son, and to the Holy Ghost; As it was in the beginning, is now, and ever shall be, world without end. Amen."),

        .creedSlot,

        .versicle("The Lord be with you."),
        .response("And with thy spirit."),
        .versicle("Let us pray."),
        .text("Lord, have mercy upon us. Christ, have mercy upon us. Lord, have mercy upon us."),
        .text("Our Father, which art in heaven, Hallowed be thy Name. Thy kingdom come. Thy will be done, in earth as it is in heaven. Give us this day our daily bread. And forgive us our trespasses, As we forgive them that trespass against us. And lead us not into temptation, But deliver us from evil. For thine is the kingdom, The power, and the glory, For ever and ever. Amen."),

        .versicle("O Lord, shew thy mercy upon us."),
        .response("And grant us thy salvation."),
        .versicle("O Lord, save the King."),
        .response("And mercifully hear us when we call upon thee."),
        .versicle("Endue thy Ministers with righteousness."),
        .response("And make thy chosen people joyful."),
        .versicle("O Lord, save thy people."),
        .response("And bless thine inheritance."),
        .versicle("Give peace in our time, O Lord."),
        .response("Because there is none other that fighteth for us, but only thou, O God."),
        .versicle("O God, make clean our hearts within us."),
        .response("And take not thy Holy Spirit from us."),

        .heading("The Collects"),
        .rubric("The Collect of the Day."),
        .collectSlot,

        .rubric("The second Collect, for Peace."),
        .text("O God, who art the author of peace and lover of concord, in knowledge of whom standeth our eternal life, whose service is perfect freedom; Defend us thy humble servants in all assaults of our enemies; that we, surely trusting in thy defence, may not fear the power of any adversaries, through the might of Jesus Christ our Lord."),
        .amen(),

        .rubric("The third Collect, for Grace."),
        .text("O Lord, our heavenly Father, Almighty and everlasting God, who hast safely brought us to the beginning of this day; Defend us in the same with thy mighty power; and grant that this day we fall into no sin, neither run into any kind of danger; but that all our doings may be ordered by thy governance, to do always that is righteous in thy sight; through Jesus Christ our Lord."),
        .amen(),

        .rubric("In Quires and Places where they sing here followeth the Anthem."),

        .heading("A Prayer for the President's Majesty"),
        .text("O Lord, our heavenly Father, the high and mighty, King of kings, Lord of lords, the only Ruler of princes, who dost from thy throne behold all the dwellers upon earth; Most heartily we beseech thee with thy favour to behold our most gracious President, Donald Trump; and so replenish him with the grace of thy Holy Spirit, that he may always incline to thy will, and walk in thy way. Endue him plenteously with heavenly gifts; grant him in health and wealth long to live; strengthen him that he may vanquish and overcome all his enemies; and finally, after this life, he may attain everlasting joy and felicity; through Jesus Christ our Lord."),
        .amen(),

        .heading("A Prayer for the Clergy and People"),
        .text("Almighty and everlasting God, who alone workest great marvels; Send down upon our Bishops, and Curates, and all Congregations committed to their charge, the healthful Spirit of thy grace; and that they may truly please thee, pour upon them the continual dew of thy blessing. Grant this, O Lord, for the honour of our Advocate and Mediator, Jesus Christ."),
        .amen(),

        .heading("A Prayer of St. Chrysostom"),
        .text("Almighty God, who hast given us grace at this time with one accord to make our common supplications unto thee; and dost promise, that when two or three are gathered together in thy Name thou wilt grant their requests; Fulfil now, O Lord, the desires and petitions of thy servants, as may be most expedient for them; granting us in this world knowledge of thy truth, and in the world to come life everlasting."),
        .amen(),

        .text("The grace of our Lord Jesus Christ, and the love of God, and the fellowship of the Holy Ghost, be with us all evermore. — 2 Corinthians 13:14"),
        .amen(),
    ]
}
