#let apa(
  title: "Title",
  author: "Firstname Lastname",
  affiliation: "Affiliation",
  course: "Course",
  instructor: "Instructor Lastname",
  duedate: datetime.today(),
  abstract: [],
  student_paper: true,
  bibliography-file: none,
  font: "New Computer Modern",
  font_size: 12pt,
  body
) = {

  set document(title: title, author: author)
  set text(
    font: font,
    size: font_size
  )

  // double spacing
  set par(leading: 1.3em)
  show heading: set block(above: 1.3em, below: 1.3em)

  // APA headings
  show heading.where(level: 1): set align(center)
  show heading.where(level: 1): set text(size: font_size)

  show heading.where(level: 2): set align(left)
  show heading.where(level: 2): set text(size: font_size)

  show heading.where(level: 3): set align(left)
  show heading.where(level: 3): set text(size: font_size, style: "italic")

  show heading.where(
    level: 4
  ): it => {
    // add period to end of body if not there
    let content = if it.body.text.last() != "." {
      it.body + [.]
    } else {
      it.body
    }
    text(
      size: font_size,
      linebreak() + h(0.5in) + content,
    )
  }

  show heading.where(
    level: 5
  ): it => {
    // add period to end of body if not there
    let content = if it.body.text.last() != "." {
      it.body + [.]
    } else {
      it.body
    }
    text(
      size: font_size,
      style: "italic",
      linebreak() + h(0.5in) + content,
    )
  }

  // figures
  show figure.caption: strong
  show figure: it => {
    set par(leading: 0.65em)
    block(
      text(
        weight: "bold",
        it.caption.supplement + " " + it.caption.counter.display()
      ) + linebreak() +
      text(
        style: "italic",
        it.caption.body
      ) +
      it.body + linebreak()
    )
    set par(leading: 1.3em)
  }
  set figure.caption(position: top)

  // top heading
  set page(
    header: [
      #if not student_paper [
        #upper[#title]
      ]
      #h(1fr)
      #counter(page).display("1")
    ],
    margin: (x: 1in, y: 1in),
  )

  // APA style recommends that the title is 3-4 line breaks from the top
  linebreak()
  linebreak()
  linebreak()
  linebreak()

  // render page title
  align(center, text()[
    *#title*
  ])

  linebreak(justify: true)

  align(center, text(12pt)[
    #author \
    #affiliation \
    #course \
    #instructor \
    #duedate.display("[month repr:long] [day padding:zero], [year]")
  ])

  pagebreak()

  // This is just an eyeball offset from the LaTeX reference im using
  v(0.5cm)

  align(center, [
    *Abstract*
  ])

  [#abstract]

  pagebreak()

  set par(first-line-indent: 0.5in)

  // temporary workaround for typst not supporting indentation on the first paragraph
  // https://github.com/typst/typst/issues/311
  show heading: it =>  {
      it

      if it.level < 4 {
        par()[#text(size:0.5in)[#h(0.0em)]#v(-0.67in)]
      }
  }

  body

  // custom biblio styling
  if bibliography-file != none {
    pagebreak()
    align(center, "References")
    show bibliography: set block(spacing: 2em)
    show bibliography: set par(
      first-line-indent: 0in,
      hanging-indent: 0.5in
    )
    bibliography(
      bibliography-file, title: none, style: "apa"
    )
  }
}