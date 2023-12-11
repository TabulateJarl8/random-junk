use std::path::{Path, PathBuf};

use rocket::{
    form::Form,
    fs::{relative, NamedFile, TempFile},
    get, post, routes, FromForm,
};
use tokio::io;

#[derive(FromForm)]
struct ImageForm<'r> {
    image: TempFile<'r>,
}

#[get("/11/assets/<path..>")]
async fn serve(path: PathBuf) -> Option<NamedFile> {
    let path = Path::new(relative!("assets")).join(path.file_name().unwrap());

    NamedFile::open(path).await.ok()
}

#[post("/11/red_pixels", data = "<image_form>")]
async fn red_pixels(image_form: Form<ImageForm<'_>>) -> String {
    let image_file = &image_form.image;
    let mut stream = image_file.open().await.unwrap();
    let mut buf = vec![];

    io::copy(&mut stream, &mut buf).await.unwrap();

    let img = image::load_from_memory(&buf).unwrap().to_rgb8();
    img.pixels()
        .filter(|&&p| p.0[0] > p.0[1].saturating_add(p.0[2]))
        .count()
        .to_string()
}

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY11", |rocket| async {
        rocket.mount("/", routes![serve, red_pixels])
    })
}
