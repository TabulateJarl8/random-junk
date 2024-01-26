#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::{
    ffi::OsStr,
    fs::File,
    io::{Read, Write},
    path::PathBuf,
};

use egui::{Color32, RichText};
use openpgp::{
    cert::CertParser,
    parse::{PacketParser, Parse},
    policy::StandardPolicy,
    serialize::stream::{Encryptor2, LiteralWriter, Message},
    Cert,
};

extern crate sequoia_openpgp as openpgp;

/// Load my public key and return it
fn load_pub_key() -> Result<Cert, anyhow::Error> {
    let ppr = PacketParser::from_bytes(include_bytes!("me.pgp"))?;
    match CertParser::from(ppr).last() {
        // there should only be one item
        Some(Ok(c)) => Ok(c),
        Some(Err(e)) => Err(e),
        None => Err(anyhow::Error::msg("PGP key not found")),
    }
}

/// Encrypt a file. Outputs it as `{filename.ext}.pgp`
fn encrypt_to_file(pub_key: &Cert, filename: &mut PathBuf) -> Result<String, anyhow::Error> {
    let mut f = File::open(&filename)?;
    let mut file_contents = Vec::new();
    f.read_to_end(&mut file_contents)?;

    let p = StandardPolicy::new();

    let recipients = pub_key
        .keys()
        .with_policy(&p, None)
        .supported()
        .alive()
        .revoked(false)
        .for_transport_encryption();
    let mut buffer: Vec<u8> = Vec::new();
    let sink: &mut (dyn Write + Send + Sync) = &mut buffer;
    let message = Message::new(sink);
    let message = Encryptor2::for_recipients(message, recipients).build()?;
    let mut message = LiteralWriter::new(message).build()?;

    message.write_all(&file_contents)?;

    message.finalize()?;

    filename.set_extension(
        filename
            .extension()
            .unwrap_or(OsStr::new("no_name"))
            .to_string_lossy()
            .to_string()
            + ".pgp",
    );
    let mut fw = File::create(&filename)?;
    fw.write_all(&buffer)?;

    Ok(filename.to_string_lossy().into_owned())
}

struct EncryptApp {
    error_msg: Option<String>,
    picked_path: Option<PathBuf>,
    pub_key: Cert,
    result_path: Option<String>,
}

impl Default for EncryptApp {
    fn default() -> Self {
        Self {
            error_msg: None,
            picked_path: None,
            pub_key: load_pub_key().unwrap(),
            result_path: None,
        }
    }
}

impl eframe::App for EncryptApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("Encrypt a File by TabulateJarl8");
            if ui.button("Choose File...").clicked() {
                if let Some(path) = rfd::FileDialog::new().pick_file() {
                    self.picked_path = Some(path);
                }
            }

            if let Some(path) = &self.picked_path {
                ui.horizontal(|ui| {
                    ui.label("File chosen:");
                    ui.monospace(path.to_string_lossy());
                });

                if ui.button("Encrypt").clicked() {
                    let mut path_copy = path.clone();
                    match encrypt_to_file(&self.pub_key, &mut path_copy) {
                        Ok(p) => {
                            self.result_path = Some(p);
                            self.error_msg = None;
                        }
                        Err(e) => {
                            self.error_msg = Some(e.to_string());
                        }
                    }
                }
            }

            if let Some(path) = &self.result_path {
                ui.horizontal(|ui| {
                    ui.label("File encrypted to:");
                    ui.monospace(path);
                });
            }

            if let Some(err) = &self.error_msg {
                ui.label(RichText::new(format!("Error: {err}")).color(Color32::RED));
            }
        });
    }
}

fn main() {
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([650.0, 300.0]),
        ..Default::default()
    };

    let _ = eframe::run_native(
        &("Encrypt a File v".to_owned() + env!("CARGO_PKG_VERSION")),
        options,
        Box::new(|_| Box::<EncryptApp>::default()),
    );
}
