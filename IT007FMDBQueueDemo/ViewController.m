//
//  ViewController.m
//  IT007FMDBQueueDemo
//
//  Created by student on 16/6/24.
//  Copyright © 2016年 Ma. All rights reserved.
//

#import "ViewController.h"
#import "FMDatabase.h"

//这个类可以保证一次只有一个程序访问线程
#import "FMDatabaseQueue.h"

@interface ViewController (){
    NSInteger count;
}

@property (strong,nonatomic) FMDatabase  *database;

@property (strong,nonatomic) NSLock  *lock;


@property (strong,nonatomic) FMDatabaseQueue    *queue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    创建一个锁，初始化对象
    self.lock = [NSLock new];
    
    
    self.database = [FMDatabase databaseWithPath:[self getPath:@"database.sqlite"]];
    
    [self.database open];
    
    BOOL  hasCreate = [self.database executeUpdate:@"CREATE TABLE IF NOT EXISTS stu (id integer PRIMARY KEY AUTOINCREMENT,name text,age integer)"];
    
    if (hasCreate) {
        NSLog(@"创建成功");
    }else {
        NSLog(@"error");
    }
    
    
    [self.database close];
    
    [self createBtn];
    
    
    self.queue = [FMDatabaseQueue databaseQueueWithPath:[self getPath:@"queue.sqlite"]];
    
    [self.queue inDatabase:^(FMDatabase *db) {// 它默认打开，也不需要我们关闭
        
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS stu (id integer PRIMARY KEY AUTOINCREMENT,name text,age integer)"];
        
    }];
    
    
    
    
}

- (void)createBtn {
    
    for (NSInteger i = 0; i < 9 ; i++) {
        
    
    
    UIButton   *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor redColor];
    button.frame = CGRectMake(20+i%3*(100+20), 50+i/3*(100+20), 100, 100);
    [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:[NSString stringWithFormat:@"%ld",i] forState:UIControlStateNormal];
    button.tag = i;
    [self.view addSubview:button];
        
    }
    
}

- (void)insertDBWithQueue:(FMDatabase *)db {
    
    NSString   *name = [NSString stringWithFormat:@"name%d",arc4random()%100];
    NSString    *age = [NSString stringWithFormat:@"%d",arc4random()%100];
    
    [db executeUpdate:@"INSERT INTO stu (name,age) values (?,?)",name,age];

    
}

- (void)testThree {
    
    for (NSInteger i=0; i<10000; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.queue inDatabase:^(FMDatabase *db) {
                [self insertDBWithQueue:db];
                NSLog(@"插入成功%ld",(long)i);
            }];
        });
    }
    
    
}

- (void)testTwo {
    
//    插入数据
    [self.queue inDatabase:^(FMDatabase *db) {
        
        for (NSInteger i = 0 ; i < 10000; i++) {
          [self insertDBWithQueue:db];
        }
        
        NSLog(@"插入完成");
        
    }];
    
}

- (void)testOne {
    
//    获得并行队列
    dispatch_queue_t  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
//    创建一个队列
    dispatch_group_t   group = dispatch_group_create();
    
    
//    外面有for，一次插入多条数据(10000条)
    for (NSInteger i = 0; i < 10000; i ++) {
//    异步执行
    dispatch_group_async(group, queue, ^{
//        进入
        dispatch_group_enter(group);
        
        [self insertDataToBase];
        
//        离开
        dispatch_group_leave(group);
        
    });
    
    }
    
//    不能同时访问，所以下面的不能用( 解决方法，要么你一次只执行一个，要么用线程锁，插入数据加锁，记得解锁)
//    在创建一个异步执行
    dispatch_group_async(group, queue, ^{
        //        进入
        dispatch_group_enter(group);
        
        [self insertDataToBase];
        
        //        离开
        dispatch_group_leave(group);
        
    });
    
//    组队列完成后的一个通知
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"---组队列完成");
    });
    
    
}

#pragma mark   ---插入数据到数据库
- (void)insertDataToBase {
    
    [self.lock lock];
    
    [self.database open];
    
    NSString   *name = [NSString stringWithFormat:@"name%d",arc4random()%100];
    NSString    *age = [NSString stringWithFormat:@"%d",arc4random()%100];
    
    [self.database executeUpdate:@"INSERT INTO stu (name,age) values (?,?)",name,age];
    
    
    [self.database close];
    
    [self.lock unlock];
}

//button点击事件
- (void)buttonClick:(UIButton *)sender {
    
    switch (sender.tag) {
        case 0:
        {
            [self testOne];
        }
            break;
        case 1:
        {
            [self testTwo];
        }
            break;
        case 2:
        {
            [self testThree];
        }
            break;
        case 3:
        {
            
        }
            break;
        case 4:
        {
            
        }
            break;
        case 5:
        {
            
        }
            break;
        case 6:
        {
            
        }
            break;
        case 7:
        {
            
        }
            break;
        case 8:
        {
            
        }
            break;
        case 9:
        {
            
        }
            break;
            
        default:
            break;
    }
    
}

- (NSString *)getPath:(NSString *)str {
    
    NSString   *path = NSHomeDirectory();
    
    NSString  *docPath = [path stringByAppendingPathComponent:@"Documents"];
    
    NSString  *strPath = [docPath stringByAppendingPathComponent:str];
    
    NSLog(@"%@",strPath);
    
    return strPath;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
