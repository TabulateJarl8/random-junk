use rocket::{
    http::Status,
    post,
    response::{content, status},
    routes,
    serde::{json::Json, Deserialize},
};
use rocket_dyn_templates::{context, Template};

#[derive(Deserialize, Debug)]
#[serde(crate = "rocket::serde")]
struct HtmlContent {
    content: String,
}

#[post("/14/unsafe", data = "<content>")]
fn unsafe_render(content: Json<HtmlContent>) -> status::Custom<content::RawHtml<String>> {
    let template = include_str!("../templates/rendering.html.hbs");
    let template = template.replace("{{content}}", &content.content);
    status::Custom(Status::Ok, content::RawHtml(template))
}

#[post("/14/safe", data = "<content>")]
fn safe_render(content: Json<HtmlContent>) -> Template {
    Template::render("rendering", context! { content: content.content.clone() })
}

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY14", |rocket| async {
        rocket.mount("/", routes![unsafe_render, safe_render])
    })
}
