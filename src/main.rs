use clap::Parser;
use crossterm::{
    cursor::{Hide, MoveTo, Show},
    execute,
    style::{Attribute, Color, Print, ResetColor, SetAttribute, SetForegroundColor},
    terminal::{size, Clear, ClearType, EnterAlternateScreen, LeaveAlternateScreen},
};
use rand::Rng;
use std::io::stdout;
use std::time::{Duration, Instant};
use ctrlc;


#[derive(Parser)]
#[command(author, about, long_about = "Available colors: black, red, green, yellow, blue, magenta, cyan, white, grey\nAvailable weather: stormy, snowy\nAvailable directions: left, right, down\nAvailable chars-on-screen: low, medium, high\nAvailable particle-on-ground: short, medium, long")]
struct Args {

    #[arg(short, long, value_parser = parse_speed, default_value = "medium", help = "Set animation speed (fast=1.5x, medium=1.0x, slow=0.5x)", long_help = "Set animation speed (fast=1.5x, medium=1.0x, slow=0.5x)")]
    speed: f32,


    #[arg(short, long, value_parser = parse_color, help = "Set drop color (black, red, green, yellow, blue, magenta, cyan, white, grey)", long_help = "Set drop color (black, red, green, yellow, blue, magenta, cyan, white, grey)")]
    color: Option<Color>,


    #[arg(short, long)]
    bold: bool,


    #[arg(short = 'w', long, value_parser = parse_weather, help = "Set weather type (stormy, snowy)", long_help = "Set weather type (stormy, snowy)")]
    weather: Option<String>,


    #[arg(long, value_parser = parse_direction, help = "Set horizontal drift (left, right, down)", long_help = "Set horizontal drift (left, right, down)")]
    direction: Option<String>,


    #[arg(long)]
    continuity: bool,


  
    #[arg(short, long, num_args = 0..=2)]
    live: Option<Vec<String>>,


    #[arg(long, help = "Set all particles to a specific character", long_help = "Set all particles to a specific character")]
    character: Option<char>,

    #[arg(long, value_parser = parse_chars_on_screen, help = "Set number of characters on screen (low, medium, high)", long_help = "Set number of characters on screen (low, medium, high)")]
    chars_on_screen: Option<String>,

    #[arg(long, value_parser = parse_particle_on_ground, help = "Set how long particles stay on ground (short, medium, long)", long_help = "Set how long particles stay on ground (short, medium, long)")]
    particle_on_ground: Option<String>,
}

fn parse_speed(s: &str) -> Result<f32, String> {
    match s.to_lowercase().as_str() {
        "fast" => Ok(1.7),
        "medium" => Ok(1.2),
        "slow" => Ok(1.0),
        _ => Err(format!("Invalid speed '{}'. Use 'fast', 'medium', or 'slow'", s)),
    }
}

fn parse_color(s: &str) -> Result<Color, String> {
    match s.to_lowercase().as_str() {
        "black" => Ok(Color::Black),
        "red" => Ok(Color::Red),
        "green" => Ok(Color::Green),
        "yellow" => Ok(Color::Yellow),
        "blue" => Ok(Color::Blue),
        "magenta" => Ok(Color::Magenta),
        "cyan" => Ok(Color::Cyan),
        "white" => Ok(Color::White),
        "grey" | "gray" => Ok(Color::Grey),
        _ => Err(format!(
            "Invalid color '{}'. Available colors: black, red, green, yellow, blue, magenta, cyan, white, grey",
            s
        )),
    }
}

fn parse_chars_on_screen(s: &str) -> Result<String, String> {
    match s.to_lowercase().as_str() {
        "low" | "medium" | "high" => Ok(s.to_lowercase()),
        _ => Err(format!("Invalid chars-on-screen '{}'. Use 'low', 'medium', or 'high'", s)),
    }
}

fn parse_particle_on_ground(s: &str) -> Result<String, String> {
    match s.to_lowercase().as_str() {
        "short" | "medium" | "long" => Ok(s.to_lowercase()),
        _ => Err(format!("Invalid particle-on-ground '{}'. Use 'short', 'medium', or 'long'", s)),
    }
}

fn parse_weather(s: &str) -> Result<String, String> {
    match s.to_lowercase().as_str() {
        "stormy" | "snowy" => Ok(s.to_lowercase()),
        _ => Err(format!("Invalid weather '{}'. Use 'stormy' or 'snowy'", s)),
    }
}

fn parse_direction(s: &str) -> Result<String, String> {
    match s.to_lowercase().as_str() {
        "left" | "right" | "down" => Ok(s.to_lowercase()),
        _ => Err(format!("Invalid direction '{}'. Use 'left', 'right', or 'down'", s)),
    }
}

fn color_to_rgb(col: Color) -> (u8, u8, u8) {
    match col {
        Color::Rgb { r, g, b } => (r, g, b),
        Color::Red => (255, 0, 0),
        Color::Green => (0, 255, 0),
        Color::Blue => (0, 0, 255),
        Color::Yellow => (255, 255, 0),
        Color::Magenta => (255, 0, 255),
        Color::Cyan => (0, 255, 255),
        Color::White => (255, 255, 255),
        Color::Black => (0, 0, 0),
        Color::Grey => (128, 128, 128),
        _ => (0, 0, 255), 
    }
}

struct Drop {
    x: f32,
    y: f32,
    speed: f32,
    glyph: char,
    grounded: bool,
    grounded_at: Option<Instant>,
    dx: f32,
    to_remove: bool,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    
    let Args {
        speed,
        color,
        bold,
        weather,
        direction,
        continuity,
        live,
        character,
        chars_on_screen,
        particle_on_ground,
    } = Args::parse();

    
    if bold && live.is_some() {
        eprintln!("Error: Cannot use --bold with --live. --live overrides color settings.");
        std::process::exit(1);
    }

    let weather = weather.unwrap_or_default().to_lowercase();
    let direction = direction.unwrap_or_else(|| "down".to_string()).to_lowercase();

    let (chars_on_screen, particle_on_ground) = if weather == "stormy" {
        (
            chars_on_screen.unwrap_or_else(|| "high".to_string()),
            particle_on_ground.unwrap_or_else(|| "long".to_string()),
        )
    } else {
        (
            chars_on_screen.unwrap_or_else(|| "medium".to_string()),
            particle_on_ground.unwrap_or_else(|| "medium".to_string()),
        )
    };

    
    let mut raindrop_chars = if weather == "stormy" {
        vec!['.', ',', '`', '\'', '|', 'o', '*', '+']
    } else if weather == "snowy" {
        vec!['*']
    } else {
        vec!['.', ',', '`', '\'', '|', 'o']
    };
    if let Some(ch) = character {
        raindrop_chars = vec![ch];
    }

    
    let speed_multiplier = if weather == "stormy" {
        if speed > 1.0 { speed } else { 1.5 }
    } else {
        speed
    };

    
    let weather_multiplier = if weather == "snowy" {
        1.0
    } else {
        1.0
    };

    
    let base_speed = speed_multiplier * weather_multiplier;

    
    let dir_multiplier = match direction.as_str() {
        "right" => 0.5,
        "left" => -0.5,
        _ => 0.0,
    };

    
    let spawn_base = match chars_on_screen.as_str() {
        "low" => if weather == "snowy" { 0.1 } else { 0.3 },
        "high" => if weather == "snowy" { 0.8 } else { 2.5 },
        _ => if weather == "snowy" { 0.4 } else { 1.2 },
    };

    let spawn_prob = (spawn_base * speed_multiplier).clamp(0.01, 0.98);

    
    let base_frame_ms = 30.0;
    let sleep_duration_ms = (base_frame_ms / speed_multiplier).clamp(5.0, 1000.0) as u64;

    let mut stdout = stdout();
    let mut rng = rand::thread_rng();

    
    execute!(stdout, EnterAlternateScreen, Hide)?;
    ctrlc::set_handler(move || {
        let mut term_stdout = std::io::stdout();
        
        let _ = execute!(term_stdout, LeaveAlternateScreen, Show);
        std::process::exit(0);
    })?;

    let (cols, rows) = size()?;
    let mut drops: Vec<Drop> = Vec::new();

    loop {
        
        if rng.gen::<f32>() < spawn_prob {
            let x = rng.gen_range(0..cols) as f32;
            
            let speed_for_drop = base_speed * rng.gen_range(0.8..1.35);
            let glyph = raindrop_chars[rng.gen_range(0..raindrop_chars.len())];
            let dx = dir_multiplier * speed_for_drop * rng.gen_range(0.8..1.2);
            drops.push(Drop {
                x,
                y: 0.0,
                speed: speed_for_drop,
                glyph,
                grounded: false,
                grounded_at: None,
                dx,
                to_remove: false,
            });
        }

        
        for drop in &mut drops {
            if !drop.grounded {
                drop.x += drop.dx;
                drop.y += drop.speed;

                
                if drop.x < 0.0 {
                    drop.x = cols as f32 - 1.0;
                } else if drop.x >= cols as f32 {
                    drop.x = 0.0;
                }

                
                if drop.y >= rows as f32 {
                    if continuity {
                        drop.to_remove = true;
                    } else {
                        drop.y = rows as f32 - 1.0;
                        drop.grounded = true;
                        drop.grounded_at = Some(Instant::now());
                    }
                }
            }
        }

        
        let grounded_life_multiplier = match particle_on_ground.as_str() {
            "short" => 0.5,
            "long" => 2.0,
            _ => 1.0,
        };
        let grounded_life = Duration::from_millis(((1200.0 * grounded_life_multiplier) / speed_multiplier as f32) as u64);
        drops.retain(|d| {
            if d.to_remove {
                false
            } else if d.grounded {
                if let Some(at) = d.grounded_at {
                    at.elapsed() <= grounded_life
                } else {
                    true
                }
            } else {
                true
            }
        });

        
        execute!(stdout, Clear(ClearType::All))?;
        for drop in &drops {
            
            let draw_x = drop.x.round().max(0.0).min(cols as f32 - 1.0) as u16;
            let draw_y = drop.y.round().max(0.0).min(rows as f32 - 1.0) as u16;

            execute!(stdout, MoveTo(draw_x, draw_y))?;

            
            
            let drop_color = if let Some(colors) = &live {
                let effective_colors = if colors.is_empty() {
                    vec!["blue".to_string(), "white".to_string()]
                } else if colors.len() == 1 {
                    vec![colors[0].clone(), "white".to_string()]
                } else {
                    colors.clone()
                };

                if effective_colors.len() >= 2 {
                    let ratio = drop.y / rows as f32;

                    let color1_result = parse_color(&effective_colors[0]);
                    let color2_result = parse_color(&effective_colors[1]);
                    if let (Ok(col1), Ok(col2)) = (color1_result, color2_result) {

                        let (r1, g1, b1) = color_to_rgb(col1);
                        let (r2, g2, b2) = color_to_rgb(col2);
                        let r = (r1 as f32 * (1.0 - ratio) + r2 as f32 * ratio) as u8;
                        let g = (g1 as f32 * (1.0 - ratio) + g2 as f32 * ratio) as u8;
                        let b = (b1 as f32 * (1.0 - ratio) + b2 as f32 * ratio) as u8;
                        Some(Color::Rgb { r, g, b })
                    } else {
                        color
                    }
                } else {
                    color
                }
            } else {
                color
            };

            
            if let Some(col) = drop_color {
                if bold {
                    execute!(
                        stdout,
                        SetForegroundColor(col),
                        SetAttribute(Attribute::Bold),
                        Print(drop.glyph),
                        ResetColor,
                        SetAttribute(Attribute::Reset)
                    )?;
                } else {
                    execute!(stdout, SetForegroundColor(col), Print(drop.glyph), ResetColor, SetAttribute(Attribute::Reset))?;
                }
            } else if bold {
                execute!(stdout, SetAttribute(Attribute::Bold), Print(drop.glyph), SetAttribute(Attribute::Reset))?;
            } else {
                execute!(stdout, Print(drop.glyph))?;
            }
        }

        std::thread::sleep(Duration::from_millis(sleep_duration_ms));
    }

    
    
}