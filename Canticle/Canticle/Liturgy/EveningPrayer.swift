import Foundation

/// The fixed text of the 1662 Order for Daily Evening Prayer. See the note in
/// `MorningPrayer.swift` about the transcription and the day-specific slots.
enum EveningPrayer {
    static let items: [LiturgyItem] = [
        .heading(Office.evening.title),

        .rubric("The Minister shall read one or more of these Sentences of Scripture."),
        .sentence("The Lord is in his holy temple: let all the earth keep silence before him. — Habakkuk 2:20"),
        .sentence("The sacrifices of God are a broken spirit: a broken and a contrite heart, O God, shalt thou not despise. — Psalm 51:17"),
        .sentence("Rend your heart, and not your garments, and turn unto the Lord your God: for he is gracious and merciful. — Joel 2:13"),

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

        .rubric("Then shall follow the Psalms in order as they are appointed."),
        .psalmsSlot,
        .text("Glory be to the Father, and to the Son, and to the Holy Ghost; As it was in the beginning, is now, and ever shall be, world without end. Amen."),

        .rubric("Then shall be read the First Lesson."),
        .firstLessonSlot,

        .canticleTitle("Magnificat. — The Song of the Blessed Virgin Mary. Luke 1:46"),
        .text("My soul doth magnify the Lord: and my spirit hath rejoiced in God my Saviour. For he hath regarded: the lowliness of his handmaiden. For behold, from henceforth: all generations shall call me blessed. For he that is mighty hath magnified me: and holy is his Name. And his mercy is on them that fear him: throughout all generations. He hath shewed strength with his arm: he hath scattered the proud in the imagination of their hearts. He hath put down the mighty from their seat: and hath exalted the humble and meek. He hath filled the hungry with good things: and the rich he hath sent empty away. He remembering his mercy hath holpen his servant Israel: as he promised to our forefathers, Abraham and his seed, for ever."),
        .text("Glory be to the Father, and to the Son, and to the Holy Ghost; As it was in the beginning, is now, and ever shall be, world without end. Amen."),

        .rubric("Then shall be read the Second Lesson."),
        .secondLessonSlot,

        .canticleTitle("Nunc Dimittis. — The Song of Simeon. Luke 2:29"),
        .text("Lord, now lettest thou thy servant depart in peace: according to thy word. For mine eyes have seen: thy salvation, Which thou hast prepared: before the face of all people; To be a light to lighten the Gentiles: and to be the glory of thy people Israel."),
        .text("Glory be to the Father, and to the Son, and to the Holy Ghost; As it was in the beginning, is now, and ever shall be, world without end. Amen."),

        .heading("Then the Apostles' Creed"),
        .text(ApostlesCreed.text),

        .versicle("The Lord be with you."),
        .response("And with thy spirit."),
        .versicle("Let us pray."),
        .text("Lord, have mercy upon us. Christ, have mercy upon us. Lord, have mercy upon us."),
        .text("Our Father, which art in heaven, Hallowed be thy Name. Thy kingdom come. Thy will be done, in earth as it is in heaven. Give us this day our daily bread. And forgive us our trespasses, As we forgive them that trespass against us. And lead us not into temptation, But deliver us from evil. For thine is the kingdom, The power, and the glory, For ever and ever. Amen."),

        .versicle("O Lord, shew thy mercy upon us."),
        .response("And grant us thy salvation."),
        .versicle("O Lord, save the President."),
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

        .rubric("The second Collect, at Evening Prayer."),
        .text("O God, from whom all holy desires, all good counsels, and all just works do proceed; Give unto thy servants that peace which the world cannot give; that both our hearts may be set to obey thy commandments, and also that by thee we, being defended from the fear of our enemies, may pass our time in rest and quietness; through the merits of Jesus Christ our Saviour."),
        .amen(),

        .rubric("The third Collect, for Aid against all Perils."),
        .text("Lighten our darkness, we beseech thee, O Lord; and by thy great mercy defend us from all perils and dangers of this night; for the love of thy only Son, our Saviour Jesus Christ."),
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
