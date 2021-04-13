﻿// <auto-generated />
using Edeka_CostAllocation;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace Edeka_CostAllocation.Migrations
{
    [DbContext(typeof(EdekaCostAllocationDbContext))]
    [Migration("20200715163444_clientadded")]
    partial class clientadded
    {
        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "3.1.5")
                .HasAnnotation("Relational:MaxIdentifierLength", 128)
                .HasAnnotation("SqlServer:ValueGenerationStrategy", SqlServerValueGenerationStrategy.IdentityColumn);

            modelBuilder.Entity("Edeka_CostAllocation.Models.AllocationKey", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int")
                        .HasAnnotation("SqlServer:ValueGenerationStrategy", SqlServerValueGenerationStrategy.IdentityColumn);

                    b.Property<string>("ClientID")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("CostUnit")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("DistributionShare")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("KeyID")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Month")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Year")
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("Id");

                    b.ToTable("allocationKeys");
                });
#pragma warning restore 612, 618
        }
    }
}
